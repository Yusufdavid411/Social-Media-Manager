import { InjectQueue } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { Queue } from 'bullmq';
import { CalendarEventType, PostStatus } from '../../../generated/prisma/enums';
import { PUBLISHING_QUEUE } from '../../common/constants/queues';
import { CalendarService } from '../calendar/calendar.service';
import { PrismaService } from '../database/prisma.service';

type SchedulePostInput = {
  workspaceId: string;
  postId: string;
  socialAccountId: string;
  platform: 'FACEBOOK' | 'INSTAGRAM' | 'LINKEDIN' | 'X' | 'TIKTOK' | 'YOUTUBE';
  scheduledAt: Date;
  timezone: string;
};

@Injectable()
export class SchedulingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly calendar: CalendarService,
    @InjectQueue(PUBLISHING_QUEUE) private readonly publishingQueue: Queue,
  ) {}

  async schedulePost(input: SchedulePostInput) {
    const scheduled = await this.prisma.scheduledPost.create({
      data: {
        workspaceId: input.workspaceId,
        postId: input.postId,
        platform: input.platform,
        scheduledAt: input.scheduledAt,
        timezone: input.timezone,
        status: PostStatus.SCHEDULED,
      },
    });

    await this.prisma.post.update({
      where: { id: input.postId },
      data: {
        status: PostStatus.SCHEDULED,
        scheduledAt: input.scheduledAt,
        socialAccountId: input.socialAccountId,
      },
    });

    await this.calendar.recordEvent({
      workspaceId: input.workspaceId,
      postId: input.postId,
      type: CalendarEventType.SCHEDULED,
      platform: input.platform,
      startsAt: input.scheduledAt,
      status: PostStatus.SCHEDULED,
    });

    await this.publishingQueue.add(
      'publish-post',
      {
        postId: input.postId,
        workspaceId: input.workspaceId,
        socialAccountId: input.socialAccountId,
      },
      {
        delay: Math.max(input.scheduledAt.getTime() - Date.now(), 0),
        attempts: 5,
        backoff: { type: 'exponential', delay: 60_000 },
      },
    );

    return scheduled;
  }
}
