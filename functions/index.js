const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendInstallmentReminder = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in to send reminders."
      );
    }

    const uid = context.auth.uid;
    const requester = await admin.firestore().collection("users").doc(uid).get();
    const requesterRole = requester.data()?.role;
    const requesterEmail = String(context.auth.token?.email || "").toLowerCase();
    const allowedAdminEmails = new Set([
      "admin17@gmail.com",
      "admin@royalnest.com",
      "admin@gmail.com",
      "superadmin@royalnest.com",
    ]);
    if (requesterRole !== "admin" && !allowedAdminEmails.has(requesterEmail)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admin can send installment reminders."
      );
    }

    const paymentId = String(data?.paymentId ?? "").trim();
    if (!paymentId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "paymentId is required."
      );
    }

    const paymentSnap = await admin.firestore().collection("payments").doc(paymentId).get();
    if (!paymentSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Payment record not found.");
    }

    const payment = paymentSnap.data();
    const targetUserId = String(data?.userId || payment?.clientId || payment?.user_id || "");
    if (!targetUserId) {
      throw new functions.https.HttpsError("failed-precondition", "Target user missing.");
    }

    const now = new Date();
    const dateKey = `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, "0")}${String(
      now.getUTCDate()
    ).padStart(2, "0")}`;
    const dedupeId = `${paymentId}_${dateKey}`;
    const dedupeRef = admin.firestore().collection("installment_reminder_logs").doc(dedupeId);
    const dedupeSnap = await dedupeRef.get();

    if (dedupeSnap.exists) {
      return { success: false, duplicate: true, message: "Reminder already sent today." };
    }

    const userSnap = await admin.firestore().collection("users").doc(targetUserId).get();
    const token = userSnap.data()?.fcmToken;

    const body = String(data?.message || "Your next installment is due soon. Please complete payment.");
    const notificationPayload = {
      title: "Installment Reminder",
      body,
    };

    let pushStatus = "token_missing";

    if (token) {
      try {
        await admin.messaging().send({
          token,
          notification: notificationPayload,
          data: {
            type: "installment_reminder",
            paymentId,
          },
        });
        pushStatus = "sent";
      } catch (error) {
        functions.logger.error("FCM send failed", error);
        pushStatus = "failed";
      }
    }

    await admin.firestore().collection("notifications").add({
      userId: targetUserId,
      targetUserId,
      title: "Installment Reminder",
      message: body,
      type: "payment_reminder",
      status: pushStatus,
      data: { paymentId },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await dedupeRef.set({
      paymentId,
      userId: targetUserId,
      status: pushStatus,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: pushStatus === "sent" || pushStatus === "token_missing", status: pushStatus };
  });
