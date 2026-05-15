import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { compare, hash } from 'bcrypt';
import {
  AuditAction,
  SubscriptionPlanCode,
  WorkspaceRole,
} from '../../../generated/prisma/enums';
import type { Workspace, WorkspaceMember } from '../../../generated/prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../database/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly audit: AuditService,
  ) {}

  async register(input: RegisterDto) {
    const email = input.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });

    if (existing) {
      throw new ConflictException('An account already exists for this email.');
    }

    const passwordHash = await hash(input.password, 12);
    const freePlan = await this.ensureFreePlan();

    const result = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email,
          passwordHash,
          displayName: input.displayName?.trim(),
        },
      });

      const workspace = await tx.workspace.create({
        data: {
          name: input.workspaceName?.trim() || 'Personal Workspace',
          slug: await this.createWorkspaceSlug(
            input.workspaceName || input.displayName || email,
          ),
          members: {
            create: {
              userId: user.id,
              role: WorkspaceRole.OWNER,
            },
          },
        },
      });

      await tx.subscription.create({
        data: {
          workspaceId: workspace.id,
          userId: user.id,
          planId: freePlan.id,
        },
      });

      return { user, workspace };
    });

    await this.audit.write({
      action: AuditAction.USER_CREATED,
      entityType: 'User',
      entityId: result.user.id,
      actorId: result.user.id,
      metadata: { email },
    });

    await this.audit.write({
      action: AuditAction.WORKSPACE_CREATED,
      entityType: 'Workspace',
      entityId: result.workspace.id,
      workspaceId: result.workspace.id,
      actorId: result.user.id,
    });

    return this.buildAuthResponse(result.user.id);
  }

  async login(input: LoginDto) {
    const email = input.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (!user?.passwordHash) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    const passwordMatches = await compare(input.password, user.passwordHash);
    if (!passwordMatches) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    return this.buildAuthResponse(user.id);
  }

  private async buildAuthResponse(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: {
        memberships: {
          include: { workspace: true },
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      email: user.email,
    });

    return {
      accessToken,
      tokenType: 'Bearer',
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
      workspaces: user.memberships.map(
        (membership: WorkspaceMember & { workspace: Workspace }) => ({
          id: membership.workspace.id,
          name: membership.workspace.name,
          slug: membership.workspace.slug,
          role: membership.role,
        }),
      ),
    };
  }

  private async ensureFreePlan() {
    return this.prisma.subscriptionPlan.upsert({
      where: { code: SubscriptionPlanCode.FREE },
      update: {},
      create: {
        code: SubscriptionPlanCode.FREE,
        name: 'Free',
        connectedAccountsLimit: 2,
        scheduledPostsPerMonth: 30,
        aiGenerationsPerMonth: 0,
        maxVideoUploadMb: 100,
        teamMembersLimit: 1,
        analyticsAccess: false,
        priorityPublishing: false,
      },
    });
  }

  private async createWorkspaceSlug(seed: string) {
    const base = seed
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '')
      .slice(0, 40);

    return `${base || 'workspace'}-${Date.now().toString(36)}`;
  }
}
