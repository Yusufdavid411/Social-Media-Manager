import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class SocialAccountsService {
  constructor(private readonly prisma: PrismaService) {}

  listForWorkspace(workspaceId: string) {
    return this.prisma.socialAccount.findMany({
      where: { workspaceId, disconnectedAt: null },
      orderBy: [{ platform: 'asc' }, { connectedAt: 'desc' }],
    });
  }
}
