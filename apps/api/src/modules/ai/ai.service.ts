import { Injectable } from '@nestjs/common';
import { Prisma } from '../../../generated/prisma/client';
import { AiActionType } from '../../../generated/prisma/enums';
import { BillingService } from '../billing/billing.service';
import { PrismaService } from '../database/prisma.service';

type TrackAiUsageInput = {
  userId: string;
  workspaceId: string;
  actionType: AiActionType;
  inputTokens?: number;
  outputTokens?: number;
  costCents?: number;
  metadata?: Prisma.InputJsonObject;
};

@Injectable()
export class AiService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly billing: BillingService,
  ) {}

  async trackUsage(input: TrackAiUsageInput) {
    await this.billing.ensureAiUsageAllowed(input.workspaceId);
    return this.prisma.aiUsage.create({ data: input });
  }

  async generateCaptionPlaceholder(userId: string, workspaceId: string) {
    await this.trackUsage({
      userId,
      workspaceId,
      actionType: AiActionType.CAPTION_GENERATION,
      metadata: { provider: 'placeholder' },
    });

    return {
      caption: 'AI caption generation placeholder.',
    };
  }
}
