import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Client } from 'minio';
import { randomUUID } from 'crypto';
import { BuildObjectKeyInput, SignedUpload, StorageService } from './storage.service';

@Injectable()
export class MinioStorageService extends StorageService {
  readonly providerName = 'minio' as const;
  private readonly client: Client;
  private readonly bucket: string;

  constructor(config: ConfigService) {
    super();
    this.bucket = config.get<string>('MINIO_BUCKET') ?? 'social-media-manager-media';
    const configuredPort = config.get<string>('MINIO_PORT');

    this.client = new Client({
      endPoint: config.get<string>('MINIO_ENDPOINT') ?? 'localhost',
      port: configuredPort ? Number(configuredPort) : undefined,
      useSSL: config.get<string>('MINIO_USE_SSL') === 'true',
      accessKey: config.get<string>('MINIO_ACCESS_KEY') ?? 'minioadmin',
      secretKey: config.get<string>('MINIO_SECRET_KEY') ?? 'minioadmin',
    });
  }

  buildObjectKey(input: BuildObjectKeyInput) {
    return `${input.workspaceId}/${input.postId}/${randomUUID()}`;
  }

  async createSignedUploadUrl(
    storageKey: string,
    _mimeType: string,
  ): Promise<SignedUpload> {
    const url = await this.client.presignedPutObject(
      this.bucket,
      storageKey,
      10 * 60,
    );
    return {
      method: 'PUT',
      url,
      storageKey,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    };
  }

  async deleteObject(storageKey: string) {
    await this.client.removeObject(this.bucket, storageKey);
  }
}
