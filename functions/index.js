"use strict";

const { v2: cloudinary } = require("cloudinary");
const { initializeApp } = require("firebase-admin/app");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

initializeApp();

const cloudinaryApiSecret = defineSecret("CLOUDINARY_API_SECRET");

exports.createCloudinaryUploadSignature = onCall(
  { secrets: [cloudinaryApiSecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to upload media.",
      );
    }

    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
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
