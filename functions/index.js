"use strict";

const { v2: cloudinary } = require("cloudinary");
const { initializeApp } = require("firebase-admin/app");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

initializeApp();

const cloudinaryCloudName = defineSecret("CLOUDINARY_CLOUD_NAME");
const cloudinaryApiKey = defineSecret("CLOUDINARY_API_KEY");
const cloudinaryApiSecret = defineSecret("CLOUDINARY_API_SECRET");

exports.createCloudinaryUploadSignature = onCall(
  {
    secrets: [
      cloudinaryCloudName,
      cloudinaryApiKey,
      cloudinaryApiSecret,
    ],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to upload media.",
      );
    }

    const cloudName = cloudinaryCloudName.value();
    const apiKey = cloudinaryApiKey.value();
    const apiSecret = cloudinaryApiSecret.value();

    if (!cloudName || !apiKey || !apiSecret) {
      throw new HttpsError(
        "failed-precondition",
        "Cloudinary configuration is incomplete.",
      );
    }

    const timestamp = Math.round(Date.now() / 1000);
    const folder = `social_media_manager/${request.auth.uid}`;
    const paramsToSign = {
      folder,
      timestamp,
    };

    const signature = cloudinary.utils.api_sign_request(
      paramsToSign,
      apiSecret,
    );

    return {
      apiKey,
      cloudName,
      folder,
      signature,
      timestamp,
    };
  },
);
