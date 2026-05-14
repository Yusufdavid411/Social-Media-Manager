import { Injectable } from '@nestjs/common';
import { PostStatus } from '../../../generated/prisma/enums';
import { PrismaService } from '../database/prisma.service';

type CreateDraftInput = {
  workspaceId: string;
  authorId: string;
  title?: string;
  caption?: string;
  postType: string;
};

@Injectable()
export class PostComposerService {
  constructor(private readonly prisma: PrismaService) {}

  createDraft(input: CreateDraftInput) {
    return this.prisma.post.create({
      data: {
        ...input,
        status: PostStatus.DRAFT,
      },
    });
  }
}
