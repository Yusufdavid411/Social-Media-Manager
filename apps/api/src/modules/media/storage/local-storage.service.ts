import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { extname } from 'path';
import { BuildObjectKeyInput, SignedUpload, StorageService } from './storage.service';

@Injectable()
export class LocalStorageService extends StorageService {
  readonly providerName = 'local' as const;

  buildObjectKey(input: BuildObjectKeyInput) {
    const extension = mimeTypeExtension(input.mimeType);
    return `${input.workspaceId}/${input.postId}/${randomUUID()}${extension}`;
  }

  async createSignedUploadUrl(
    storageKey: string,
    _mimeType: string,
  ): Promise<SignedUpload> {
    return {
      method: 'PUT',
      url: `/dev-storage/${storageKey}`,
      storageKey,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    };
  }

  async deleteObject(_storageKey: string) {
    return;
  }
}

function mimeTypeExtension(mimeType: string) {
  const known: Record<string, string> = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
    'video/mp4': '.mp4',
    'video/quicktime': '.mov',
  };
  return known[mimeType] ?? extname(mimeType) ?? '';
}
