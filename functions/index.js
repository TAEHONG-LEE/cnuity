import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();
const db = getFirestore();

export const wakeReminderJob = onSchedule("every 1 minutes", async (event) => {
  const now = new Date();
  const GRACE_SECONDS = 10;

  const seatSnaps = await db.collectionGroup("seats")
    .where("status", "==", "sleeping")
    .get();

  for (const seatDoc of seatSnaps.docs) {
    const data = seatDoc.data();
    const sleepStart = data.sleepStart?.toDate?.();
    const sleepDuration = data.sleepDuration;
    const reservedBy = data.reservedBy;
    const seatId = data.seatId;
    const parentRoomRef = seatDoc.ref.parent.parent;

    if (!sleepStart || !sleepDuration || !seatId || !reservedBy || !parentRoomRef) continue;

    const wakeDeadline = new Date(sleepStart.getTime() + sleepDuration * 1000 + GRACE_SECONDS * 1000);
    if (now < wakeDeadline) continue;

    const centerId = parseInt(seatId);
    for (let offset = -20; offset <= 20; offset++) {
      if (offset === 0) continue;
      const neighborId = String(centerId + offset);

      const neighborRef = parentRoomRef.collection("seats").doc(neighborId);
      const neighborSnap = await neighborRef.get();
      if (!neighborSnap.exists) continue;

      const neighborData = neighborSnap.data();
      const neighborUid = neighborData?.reservedBy;
      if (!neighborUid) continue;

      // ✅ 자기 자신에게는 별도 메시지
      if (neighborUid === reservedBy) {
        await db.collection("users").doc(reservedBy).collection("notifications").add({
          title: `일어날 시간이에요!`,
          body: `${seatId}번 좌석에서 일어나주세요.`,
          createdAt: FieldValue.serverTimestamp(),
          targetSeat: seatId,
        });

        const tokenSnap = await db.collection("users").doc(reservedBy).collection("fcmTokens").get();
        const tokens = tokenSnap.docs.map(doc => doc.id);
        if (tokens.length > 0) {
          await getMessaging().sendEachForMulticast({
            tokens,
            notification: {
              title: `일어날 시간이에요!`,
              body: `${seatId}번 좌석에서 일어나주세요.`,
            },
            data: { targetSeat: seatId },
          });
          console.log(`📢 자기자신에게 알림 보냄 → ${reservedBy}`);
        }

        continue; // ❗ 중복 푸시 방지
      }

      // 🔔 다른 사용자에게 알림
      await db.collection("users").doc(neighborUid).collection("notifications").add({
        title: `${seatId}번 사용자가 아직 일어나지 않았어요`,
        body: `QR을 스캔해 기상 도와주면 포인트를 받을 수 있어요!`,
        createdAt: FieldValue.serverTimestamp(),
        targetSeat: seatId,
      });

      const tokenSnap = await db.collection("users").doc(neighborUid).collection("fcmTokens").get();
      const tokens = tokenSnap.docs.map(doc => doc.id);
      if (tokens.length > 0) {
        await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: `${seatId}번 사용자가 아직 일어나지 않았어요`,
            body: `QR을 스캔해 기상 도와주면 포인트를 받을 수 있어요!`,
          },
          data: { targetSeat: seatId },
        });
        console.log(`🚨 알림 보냄 → ${neighborUid} (${tokens.length}개)`);
      }
    }

    // 🔄 상태 업데이트
    await seatDoc.ref.update({ status: "wake_waiting" });
    console.log(`🔄 상태 변경 → wake_waiting: ${seatId}`);
  }

  return null;
});
