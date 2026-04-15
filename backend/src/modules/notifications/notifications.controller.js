// Placeholder — Firebase Cloud Messaging notifications module
// To implement: install firebase-admin and configure serviceAccountKey.json

const NotificationsController = {
  async sendBudgetAlert(userId, message) {
    // TODO: firebase-admin FCM send
    console.log(`[FCM] Budget alert for ${userId}: ${message}`);
  },
};

module.exports = NotificationsController;
