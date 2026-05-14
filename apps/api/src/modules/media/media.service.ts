import { BadRequestException, Injectable } from '@nestjs/common';
import { MediaFileType, MediaUploadStatus, StorageProvider } from '../../../generated/prisma/enums';
import { PrismaService } from '../database/prisma.service';
import { StorageService } from './storage/storage.service';

type CreateMediaRecordInput = {
  ownerId: string;
  workspaceId: string;
  postId: string;
  fileType: MediaFileType;
  size: bigint;
  mimeType: string;
  durationSeconds?: number;
};

@Injectable()
export class MediaService {
  private readonly allowedMimeTypes = new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/quicktime',
  ]);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  async createTemporaryMediaRecord(input: CreateMediaRecordInput) {
    if (!this.allowedMimeTypes.has(input.mimeType)) {
      throw new BadRequestException('Unsupported media MIME type.');
    }

    const storageKey = this.storage.buildObjectKey({
      workspaceId: input.workspaceId,
      postId: input.postId,
      mimeType: input.mimeType,
    });

    return this.prisma.postMedia.create({
      data: {
        ...input,
        storageProvider:
          this.storage.providerName === 'minio'
            ? StorageProvider.MINIO
            : StorageProvider.LOCAL,
        storageKey,
        uploadStatus: MediaUploadStatus.REQUESTED,
      },
    });
  }

  createSignedUploadUrl(storageKey: string, mimeType: string) {
    return this.storage.createSignedUploadUrl(storageKey, mimeType);
  }

  async deleteStoredMedia(mediaId: string) {
    const media = await this.prisma.postMedia.findUniqueOrThrow({
      where: { id: mediaId },
    });
    await this.storage.deleteObject(media.storageKey);
    if (media.processedStorageKey) {
      await this.storage.deleteObject(media.processedStorageKey);
    }
    return this.prisma.postMedia.update({
      where: { id: media.id },
      data: {
        uploadStatus: MediaUploadStatus.DELETED,
        deletedAt: new Date(),
        publicPreviewUrl: null,
        signedUrl: null,
      },
    });
  }
}
