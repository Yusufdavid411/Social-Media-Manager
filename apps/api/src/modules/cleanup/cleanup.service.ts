import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AuditAction, CleanupJobStatus, MediaUploadStatus } from '../../../generated/prisma/enums';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../database/prisma.service';
import { MediaService } from '../media/media.service';

@Injectable()
export class CleanupService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly media: MediaService,
    private readonly audit: AuditService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async runDailyRetentionCleanup() {
    return this.runRetentionCleanup();
  }

  async runRetentionCleanup() {
    const cleanupJob = await this.prisma.cleanupJob.create({
      data: { status: CleanupJobStatus.RUNNING, startedAt: new Date() },
    });

    const expiredMedia = await this.prisma.postMedia.findMany({
      where: {
        deleteAfter: { lte: new Date() },
        uploadStatus: { not: MediaUploadStatus.DELETED },
      },
      take: 500,
    });

    let deletedCount = 0;

    for (const media of expiredMedia) {
      await this.media.deleteStoredMedia(media.id);
      await this.audit.write({
        action: AuditAction.MEDIA_DELETED,
        entityType: 'PostMedia',
        entityId: media.id,
        workspaceId: media.workspaceId,
        actorId: media.ownerId,
        metadata: { reason: 'retention_expired' },
      });
      deletedCount += 1;
    }

    await this.prisma.post.updateMany({
      where: {
        deletePayloadAfter: { lte: new Date() },
      },
      data: {
        caption: null,
      },
    });

    return this.prisma.cleanupJob.update({
      where: { id: cleanupJob.id },
      data: {
        status: CleanupJobStatus.SUCCEEDED,
        completedAt: new Date(),
        scannedCount: expiredMedia.length,
        deletedCount,
      },
    });
  }
}
