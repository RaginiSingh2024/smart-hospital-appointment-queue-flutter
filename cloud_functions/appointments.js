const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// CORS configuration
const cors = require('cors')({ origin: true });

// GET /appointments/patient/{patientId}
exports.getAppointmentsByPatient = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).send({ error: 'Method not allowed' });
    }

    try {
      const patientId = req.params.patientId;
      const snapshot = await db.collection('appointments')
        .where('patientId', '==', patientId)
        .orderBy('appointmentDate', 'desc')
        .get();

      const appointments = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      res.status(200).json(appointments);
    } catch (error) {
      console.error('Error fetching appointments:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// GET /appointments/doctor/{doctorId}
exports.getAppointmentsByDoctor = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).send({ error: 'Method not allowed' });
    }

    try {
      const doctorId = req.params.doctorId;
      const snapshot = await db.collection('appointments')
        .where('doctorId', '==', doctorId)
        .orderBy('appointmentDate', 'desc')
        .get();

      const appointments = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      res.status(200).json(appointments);
    } catch (error) {
      console.error('Error fetching appointments:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// POST /appointments
exports.createAppointment = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send({ error: 'Method not allowed' });
    }

    try {
      const appointmentData = req.body;
      const docRef = await db.collection('appointments').add({
        ...appointmentData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const doc = await docRef.get();
      res.status(201).json({ id: doc.id, ...doc.data() });
    } catch (error) {
      console.error('Error creating appointment:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// PATCH /appointments/{appointmentId}
exports.updateAppointment = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'PATCH') {
      return res.status(405).send({ error: 'Method not allowed' });
    }

    try {
      const appointmentId = req.params.appointmentId;
      const updates = req.body;

      await db.collection('appointments').doc(appointmentId).update({
        ...updates,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const doc = await db.collection('appointments').doc(appointmentId).get();
      res.status(200).json({ id: doc.id, ...doc.data() });
    } catch (error) {
      console.error('Error updating appointment:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// POST /appointments/{appointmentId}/cancel
exports.cancelAppointment = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send({ error: 'Method not allowed' });
    }

    try {
      const appointmentId = req.params.appointmentId;

      await db.collection('appointments').doc(appointmentId).update({
        status: 'cancelled',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(200).json({ message: 'Appointment cancelled successfully' });
    } catch (error) {
      console.error('Error cancelling appointment:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

// GET /appointments/statistics
exports.getAppointmentStatistics = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).send({ error: 'Method not allowed' });
    }

    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const todaySnapshot = await db.collection('appointments')
        .where('appointmentDate', '>=', today)
        .where('appointmentDate', '<', tomorrow)
        .get();

      const allSnapshot = await db.collection('appointments').get();

      const todayAppointments = todaySnapshot.size;
      const totalAppointments = allSnapshot.size;
      const completedAppointments = allSnapshot.docs.filter(doc => doc.data().status === 'completed').length;
      const cancelledAppointments = allSnapshot.docs.filter(doc => doc.data().status === 'cancelled').length;

      res.status(200).json({
        todayAppointments,
        totalAppointments,
        completedAppointments,
        cancelledAppointments,
        pendingAppointments: totalAppointments - completedAppointments - cancelledAppointments,
      });
    } catch (error) {
      console.error('Error fetching statistics:', error);
      res.status(500).json({ error: error.message });
    }
  });
});
