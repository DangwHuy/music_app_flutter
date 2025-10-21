const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
     *
 Sends a notification to the post owner when a new like is added.
     */
exports.onNewLike = functions.firestore
    .document("/posts/{postId}")
    .onUpdate(async (change, context) => {
      const beforeData = change.before.data();
      const
        afterData = change.after.data();

      const beforeLikes = beforeData.likes || [];
      const afterLikes = afterData.likes || [];

      // Check if a new like was added
      if (afterLikes.length > beforeLikes.length) {
        const
          newLikerId = afterLikes.find((id) => !beforeLikes.includes(id));
        const postOwnerId = afterData.userId;

        // Don't send notification for self-likes
        if (newLikerId === postOwnerId) {
          return null;
        }


        const likerDoc = await admin
            .firestore()
            .collection("users")
            .doc(newLikerId)
            .get();
        const ownerDoc = await admin
            .firestore()
            .collection("users")
            .doc(postOwnerId)
            .get();

        if (!likerDoc.exists || !ownerDoc.exists) {
          return null;
        }


        const likerUsername = likerDoc.data().username;
        const ownerTokens = ownerDoc.data().fcmTokens;

        if (!ownerTokens || ownerTokens.length === 0) {
          return null; // No tokens to send to
        }


        const payload = {
          notification: {
            title: "New Like!",
            body: `${likerUsername} liked your post.`,
            sound: "default",
          },
        };


        return admin.messaging().sendToDevice(ownerTokens, payload);
      }

      return null;
    });

/**
     * Sends a notification to the post owner when a new comment is added.
     */
exports.onNewComment = functions.firestore
    .document("/posts/{postId}/comments/{commentId}")
    .onCreate(async (snap, context) => {
      const commentData = snap.data();
      const postId = context.params.postId;
      const commenterId = commentData.userId;


      const postDoc = await admin
          .firestore()
          .collection("posts")
          .doc(postId)
          .get();
      if (!postDoc.exists) {
        return null;
      }

      const postOwnerId = postDoc.data().userId;


      // Don't send notification for self-comments
      if (commenterId === postOwnerId) {
        return null;
      }

      const commenterDoc = await admin
          .firestore()
          .collection("users")
          .doc(commenterId)
          .get();
      const ownerDoc = await admin
          .firestore()
          .collection("users")
          .doc(postOwnerId)
          .get();


      if (!commenterDoc.exists || !ownerDoc.exists) {
        return null;
      }

      const commenterUsername = commenterDoc.data().username;
      const ownerTokens = ownerDoc.data().fcmTokens;


      if (!ownerTokens || ownerTokens.length === 0) {
        return null; // No tokens to send to
      }

      const payload = {
        notification: {
          title: "New Comment",
          body: `${commenterUsername} commented: ${commentData.text}`,

          sound: "default",
        },
      };

      return admin.messaging().sendToDevice(ownerTokens, payload);
    });
