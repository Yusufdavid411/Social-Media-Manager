import { Injectable } from '@nestjs/common';
import { SubscriptionPlanCode } from '../../../generated/prisma/enums';
import { PrismaService } from '../database/prisma.service';

export type PlanLimits = {
  connectedAccountsLimit: number;
  scheduledPostsPerMonth: number;
  aiGenerationsPerMonth: number;
  maxVideoUploadMb: number;
  teamMembersLimit: number;
  analyticsAccess: boolean;
  priorityPublishing: boolean;
};

@Injectable()
export class BillingService {
  constructor(private readonly prisma: PrismaService) {}

  async getWorkspacePlan(workspaceId: string) {
    const subscription = await this.prisma.subscription.findFirst({
      where: { workspaceId },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    return subscription?.plan ?? this.defaultFreePlan();
  }

  async ensureAiUsageAllowed(workspaceId: string) {
    const plan = await this.getWorkspacePlan(workspaceId);
    if (plan.aiGenerationsPerMonth <= 0) {
      throw new Error('AI usage is not available on this plan.');
    }
  }

  private defaultFreePlan(): PlanLimits & {
    code: SubscriptionPlanCode;
    name: string;
  } {
    return {
      code: SubscriptionPlanCode.FREE,
      name: 'Free',
      connectedAccountsLimit: 2,
      scheduledPostsPerMonth: 30,
      aiGenerationsPerMonth: 0,
      maxVideoUploadMb: 100,
      teamMembersLimit: 1,
      analyticsAccess: false,
      priorityPublishing: false,
    };
  }
}
