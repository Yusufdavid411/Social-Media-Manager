import { Injectable } from '@nestjs/common';
import { Prisma } from '../../../generated/prisma/client';
import {
  CalendarEventType,
  PostStatus,
  SocialPlatform,
} from '../../../generated/prisma/enums';
import { PrismaService } from '../database/prisma.service';

type RecordCalendarEventInput = {
  workspaceId: string;
  postId: string;
  type: CalendarEventType;
  platform?: SocialPlatform;
  startsAt: Date;
  status: PostStatus;
  title?: string;
  metadata?: Prisma.InputJsonObject;
};

@Injectable()
export class CalendarService {
  constructor(private readonly prisma: PrismaService) {}

  recordEvent(input: RecordCalendarEventInput) {
    return this.prisma.calendarEvent.create({ data: input });
  }

  listWorkspaceEvents(workspaceId: string, from: Date, to: Date) {
    return this.prisma.calendarEvent.findMany({
      where: {
        workspaceId,
        startsAt: { gte: from, lte: to },
      },
      orderBy: { startsAt: 'asc' },
    });
  }
}
