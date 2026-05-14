import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MediaService } from './media.service';
import { LocalStorageService } from './storage/local-storage.service';
import { MinioStorageService } from './storage/minio-storage.service';
import { StorageService } from './storage/storage.service';

@Module({
  imports: [ConfigModule],
  providers: [
    MediaService,
    LocalStorageService,
    MinioStorageService,
    {
      provide: StorageService,
      useFactory: (
        local: LocalStorageService,
        minio: MinioStorageService,
      ) => {
        return process.env.STORAGE_DRIVER === 'minio' ? minio : local;
      },
      inject: [LocalStorageService, MinioStorageService],
    },
  ],
  exports: [MediaService, StorageService],
})
export class MediaModule {}
