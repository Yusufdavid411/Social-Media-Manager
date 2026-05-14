import { Injectable } from '@nestjs/common';
import { CalendarEventType, MediaUploadStatus, PostStatus } from '../../../generated/prisma/enums';
import { AuditAction } from '../../../generated/prisma/enums';
import { AuditService } from '../audit/audit.service';
import { CalendarService } from '../calendar/calendar.service';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class PublishingService {
  private readonly retentionDays = Number(process.env.MEDIA_RETENTION_DAYS ?? 15);

  constructor(
    private readonly prisma: PrismaService,
    private readonly calendar: CalendarService,
    private readonly audit: AuditService,
  ) {}

  async publishPost(jobId: string, postId: string) {
    const post = await this.prisma.post.findUniqueOrThrow({
      where: { id: postId },
      include: { media: true, socialAccount: true },
    });

    await this.prisma.post.update({
      where: { id: post.id },
      data: { status: PostStatus.PUBLISHING },
    });

    // Platform API integration belongs here. The frontend never publishes
    // directly; workers publish and retry through BullMQ.
    const publishedAt = new Date();
    const deleteAfter = new Date(
      publishedAt.getTime() + this.retentionDays * 24 * 60 * 60 * 1000,
    );

    await this.prisma.post.update({
      where: { id: post.id },
      data: {
        status: PostStatus.PUBLISHED,
        publishedAt,
        deletePayloadAfter: deleteAfter,
        externalPlatformPostId: `placeholder-${jobId}`,
      },
    });

    await this.prisma.postMedia.updateMany({
      where: {
        postId: post.id,
        uploadStatus: { not: MediaUploadStatus.DELETED },
      },
      data: { deleteAfter },
    });

    await this.calendar.recordEvent({
      workspaceId: post.workspaceId,
      postId: post.id,
      type: CalendarEventType.PUBLISHED,
      platform: post.socialAccount?.platform,
      startsAt: publishedAt,
      status: PostStatus.PUBLISHED,
      metadata: { retention: { deleteAfter } },
    });

    await this.audit.write({
      action: AuditAction.POST_PUBLISHED,
      entityType: 'Post',
      entityId: post.id,
      workspaceId: post.workspaceId,
      actorId: post.authorId,
      metadata: { deleteAfter },
    });
  }
}
