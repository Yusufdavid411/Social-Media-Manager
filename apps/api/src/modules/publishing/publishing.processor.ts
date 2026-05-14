import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PUBLISHING_QUEUE } from '../../common/constants/queues';
import { PublishingService } from './publishing.service';

type PublishJobData = {
  postId: string;
  workspaceId: string;
  socialAccountId: string;
};

@Processor(PUBLISHING_QUEUE)
export class PublishingProcessor extends WorkerHost {
  private readonly logger = new Logger(PublishingProcessor.name);

  constructor(private readonly publishing: PublishingService) {
    super();
  }

  async process(job: Job<PublishJobData>) {
    this.logger.log(`Publishing post ${job.data.postId}`);
    await this.publishing.publishPost(job.id ?? job.name, job.data.postId);
  }
}
