export type BuildObjectKeyInput = {
  workspaceId: string;
  postId: string;
  mimeType: string;
};

export type SignedUpload = {
  method: 'PUT';
  url: string;
  storageKey: string;
  expiresAt: Date;
};

export abstract class StorageService {
  abstract readonly providerName: 'local' | 'minio';
  abstract buildObjectKey(input: BuildObjectKeyInput): string;
  abstract createSignedUploadUrl(
    storageKey: string,
    mimeType: string,
  ): Promise<SignedUpload>;
  abstract deleteObject(storageKey: string): Promise<void>;
}
