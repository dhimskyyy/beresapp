import React, { createContext, useContext, useState, useEffect } from 'react';
import { 
  collection, 
  doc, 
  onSnapshot, 
  setDoc 
} from 'firebase/firestore';
import { db } from '../firebase';
import { 
  initialTukangList, 
  initialUsersList, 
  initialTicketsList, 
  initialWithdrawalsList 
} from '../data/mockData';

const AdminDataContext = createContext();

// Category dictionary for Indonesian labels
const CATEGORY_LABELS = {
  ac: 'Servis AC',
  plumbing: 'Plumbing & Pipa',
  las: 'Teralis & Las',
  cleaning: 'Home Cleaning',
  elektronik: 'Elektronik',
  bangunan: 'Renovasi Bangunan',
  besi_baja: 'Besi & Baja',
  bengkel_motor: 'Bengkel Motor',
  bengkel_mobil: 'Bengkel Mobil',
  pengrajin_kayu: 'Pengrajin Kayu'
};

// State machine status dictionary for Indonesian labels
const STATUS_LABELS = {
  OPEN: 'Menunggu Penawaran',
  BIDDING: 'Ada Penawaran Mitra',
  LOCKED: 'Mitra Terpilih',
  ON_THE_WAY: 'Tukang Menuju Lokasi',
  ARRIVED: 'Tiba di Lokasi',
  IN_PROGRESS: 'Pengerjaan Berlangsung',
  WORK_COMPLETED: 'Pekerjaan Selesai',
  PAYMENT_PENDING: 'Menunggu Pembayaran',
  COMPLETED: 'Selesai & Lunas',
  CANCELED: 'Dibatalkan'
};

// Normalizers to bridge mobile Firestore schema with Admin UI
const normalizeTicket = (docData, docId) => {
  return {
    ...docData,
    id: docId || docData.id,
    categoryLabel: CATEGORY_LABELS[docData.category] || docData.categoryLabel || docData.category || 'Jasa Umum',
    statusLabel: STATUS_LABELS[docData.status] || docData.statusLabel || docData.status || 'Aktif',
    issuePhotos: docData.photoUrls || docData.issuePhotos || [],
    beforePhotos: docData.beforePhotos || [],
    afterPhotos: docData.afterPhotos || [],
    bids: docData.bids || [],
    location: docData.location || { lat: -6.2088, lng: 106.8456 },
    rating: docData.rating || (docData.ratingStars ? { stars: docData.ratingStars, review: docData.ratingReview } : null),
  };
};

const normalizeTukang = (docData, docId) => {
  return {
    ...docData,
    id: docId || docData.id,
    verificationStatus: docData.verificationStatus || 'pending_verification',
    statusText: docData.statusText || (docData.isOnline ? 'Online / Siap Kerja' : 'Offline'),
    services: docData.services || [],
    payoutAccounts: docData.payoutAccounts || [],
    isSuspended: Boolean(docData.isSuspended),
    walletBalance: docData.walletBalance || 0,
    rating: docData.rating || 5.0,
    reviewCount: docData.reviewCount || 0,
  };
};

const mergeTickets = (cloudDocs) => {
  const mergedMap = new Map();
  for (const item of cloudDocs) {
    mergedMap.set(item.id, normalizeTicket(item, item.id));
  }
  return Array.from(mergedMap.values()).sort((a, b) => {
    const timeA = new Date(a.createdAt || 0).getTime();
    const timeB = new Date(b.createdAt || 0).getTime();
    return timeB - timeA;
  });
};

const mergeTukang = (cloudDocs) => {
  const mergedMap = new Map();
  for (const item of cloudDocs) {
    mergedMap.set(item.id, normalizeTukang(item, item.id));
  }
  return Array.from(mergedMap.values());
};

const normalizeWithdrawal = (docData, docId) => {
  const payoutTarget = docData.payoutTarget || {};
  let formattedDate = 'Baru saja';
  if (docData.requestedAt) {
    formattedDate = docData.requestedAt;
  } else if (docData.createdAt) {
    try {
      const d = new Date(docData.createdAt);
      formattedDate = d.toLocaleDateString('id-ID', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }) + ' WIB';
    } catch (_) {
      formattedDate = String(docData.createdAt);
    }
  }

  return {
    ...docData,
    id: docId || docData.id,
    amount: Number(docData.amount) || 0,
    tukangName: docData.tukangName || 'Mitra Beres',
    payoutTarget: {
      type: payoutTarget.type || 'bank',
      provider: payoutTarget.provider || 'BCA',
      accountNumber: payoutTarget.accountNumber || '-',
      accountName: payoutTarget.accountName || docData.tukangName || '-'
    },
    status: docData.status || 'pending',
    requestedAt: formattedDate,
    createdAt: docData.createdAt || new Date().toISOString()
  };
};

const mergeWithdrawals = (cloudDocs) => {
  const mergedMap = new Map();
  for (const item of cloudDocs) {
    mergedMap.set(item.id, normalizeWithdrawal(item, item.id));
  }
  return Array.from(mergedMap.values()).sort((a, b) => {
    const timeA = new Date(a.createdAt || 0).getTime();
    const timeB = new Date(b.createdAt || 0).getTime();
    return timeB - timeA;
  });
};

export function AdminDataProvider({ children }) {
  const demoMode = import.meta.env.VITE_BERES_DEMO_MODE === 'true';
  const [tukangList, setTukangList] = useState(() => {
    return demoMode ? initialTukangList : [];
  });

  const [usersList, setUsersList] = useState(() => {
    return demoMode ? initialUsersList : [];
  });

  const [ticketsList, setTicketsList] = useState(() => {
    return demoMode ? initialTicketsList : [];
  });

  const [withdrawalsList, setWithdrawalsList] = useState(() => {
    return demoMode ? initialWithdrawalsList : [];
  });

  const [dataLoading, setDataLoading] = useState({
    tickets: !demoMode,
    tukang: !demoMode,
    withdrawals: !demoMode,
    users: !demoMode,
  });

  const [dataErrors, setDataErrors] = useState({
    tickets: null,
    tukang: null,
    withdrawals: null,
    users: null,
  });

  const [toast, setToast] = useState(null);
  const [isLiveConnected, setIsLiveConnected] = useState(false);

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 4000);
  };

  // 1. Sync with Cloud Firestore Realtime: tickets collection
  useEffect(() => {
    let unsubscribe;
    try {
      unsubscribe = onSnapshot(collection(db, 'tickets'), (snapshot) => {
        setIsLiveConnected(true);
        setDataLoading(prev => ({ ...prev, tickets: false }));
        setDataErrors(prev => ({ ...prev, tickets: null }));
        if (!snapshot.empty) {
          const docs = snapshot.docs.map(d => ({ ...d.data(), id: d.id }));
          setTicketsList(() => mergeTickets(docs));
        } else {
          setTicketsList([]);
        }
      }, (error) => {
        console.warn('Firestore tickets realtime listener notice:', error);
        setDataLoading(prev => ({ ...prev, tickets: false }));
        setDataErrors(prev => ({ ...prev, tickets: error.message }));
      });
    } catch (e) {
      console.warn('Firestore tickets setup notice:', e);
      setTimeout(() => {
        setDataLoading(prev => ({ ...prev, tickets: false }));
        setDataErrors(prev => ({ ...prev, tickets: e.message }));
      }, 0);
    }
    return () => unsubscribe && unsubscribe();
  }, []);

  // 2. Sync with Cloud Firestore Realtime: tukang collection
  useEffect(() => {
    let unsubscribe;
    try {
      unsubscribe = onSnapshot(collection(db, 'tukang'), (snapshot) => {
        setIsLiveConnected(true);
        setDataLoading(prev => ({ ...prev, tukang: false }));
        setDataErrors(prev => ({ ...prev, tukang: null }));
        if (!snapshot.empty) {
          const docs = snapshot.docs.map(d => ({ ...d.data(), id: d.id }));
          setTukangList(() => mergeTukang(docs));
        } else {
          setTukangList([]);
        }
      }, (error) => {
        console.warn('Firestore tukang realtime listener notice:', error);
        setDataLoading(prev => ({ ...prev, tukang: false }));
        setDataErrors(prev => ({ ...prev, tukang: error.message }));
      });
    } catch (e) {
      console.warn('Firestore tukang setup notice:', e);
      setTimeout(() => {
        setDataLoading(prev => ({ ...prev, tukang: false }));
        setDataErrors(prev => ({ ...prev, tukang: e.message }));
      }, 0);
    }
    return () => unsubscribe && unsubscribe();
  }, []);

  // 3. Sync with Cloud Firestore Realtime: withdrawals collection
  useEffect(() => {
    let unsubscribe;
    try {
      unsubscribe = onSnapshot(collection(db, 'withdrawals'), (snapshot) => {
        setIsLiveConnected(true);
        setDataLoading(prev => ({ ...prev, withdrawals: false }));
        setDataErrors(prev => ({ ...prev, withdrawals: null }));
        if (!snapshot.empty) {
          const docs = snapshot.docs.map(d => ({ ...d.data(), id: d.id }));
          setWithdrawalsList(() => mergeWithdrawals(docs));
        } else {
          setWithdrawalsList([]);
        }
      }, (error) => {
        console.warn('Firestore withdrawals realtime listener notice:', error);
        setDataLoading(prev => ({ ...prev, withdrawals: false }));
        setDataErrors(prev => ({ ...prev, withdrawals: error.message }));
      });
    } catch (e) {
      console.warn('Firestore withdrawals setup notice:', e);
      setTimeout(() => {
        setDataLoading(prev => ({ ...prev, withdrawals: false }));
        setDataErrors(prev => ({ ...prev, withdrawals: e.message }));
      }, 0);
    }
    return () => unsubscribe && unsubscribe();
  }, []);

  // 4. Sync users from Cloud Firestore in realtime
  useEffect(() => {
    let unsubscribe;
    try {
      unsubscribe = onSnapshot(collection(db, 'users'), (snapshot) => {
        setIsLiveConnected(true);
        setDataLoading(prev => ({ ...prev, users: false }));
        setDataErrors(prev => ({ ...prev, users: null }));
        setUsersList(snapshot.docs.map((item) => ({ ...item.data(), id: item.id })));
      }, (error) => {
        console.warn('Firestore users realtime listener notice:', error);
        setDataLoading(prev => ({ ...prev, users: false }));
        setDataErrors(prev => ({ ...prev, users: error.message }));
      });
    } catch (e) {
      console.warn('Firestore users setup notice:', e);
      setTimeout(() => {
        setDataLoading(prev => ({ ...prev, users: false }));
        setDataErrors(prev => ({ ...prev, users: e.message }));
      }, 0);
    }
    return () => unsubscribe && unsubscribe();
  }, []);

  // KYC Approval: update Firestore with real data
  const approveKyc = async (tukangId) => {
    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        verificationStatus: 'verified',
        statusText: 'Terverifikasi',
        rejectionReason: null,
        updatedAt: new Date().toISOString()
      }, { merge: true });
      showToast(`Pendaftaran Mitra #${tukangId} berhasil disetujui. Akun mitra aktif!`);
    } catch (e) {
      console.warn('Firestore approveKyc error:', e);
      showToast('Gagal menyetujui pendaftaran mitra. Coba lagi.', 'error');
    }
  };

  // KYC Rejection: update Firestore with reason
  const rejectKyc = async (tukangId, reason) => {
    const finalReason = reason || 'Keahlian atau kontak belum memenuhi kriteria.';
    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        verificationStatus: 'rejected',
        statusText: 'Pendaftaran Ditolak',
        isOnline: false,
        rejectionReason: finalReason,
        updatedAt: new Date().toISOString()
      }, { merge: true });
      showToast(`Pendaftaran Mitra #${tukangId} ditolak. Notifikasi perbaikan dikirim.`, 'error');
    } catch (e) {
      console.warn('Firestore rejectKyc error:', e);
      showToast('Gagal menolak pendaftaran mitra. Coba lagi.', 'error');
    }
  };

  // Suspend Tukang
  const suspendTukang = async (tukangId, reason, days = 3) => {
    const suspendDurationMs = days * 24 * 60 * 60 * 1000;
    const suspendedUntil = new Date(Date.now() + suspendDurationMs).toISOString();
    const finalReason = reason || 'Pelanggaran ketentuan layanan Beres';

    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        isSuspended: true,
        suspendedUntil,
        suspendReason: finalReason,
        isOnline: false,
        statusText: `Suspended (${days} Hari)`,
        updatedAt: new Date().toISOString()
      }, { merge: true });
      showToast(`Tukang #${tukangId} resmi disuspend selama ${days} hari!`, 'error');
    } catch (e) {
      console.warn('Firestore suspendTukang error:', e);
      showToast('Gagal menerapkan suspend. Coba lagi.', 'error');
    }
  };

  // Lift Suspend Early
  const unsuspendTukang = async (tukangId) => {
    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        isSuspended: false,
        suspendedUntil: null,
        suspendReason: null,
        statusText: 'Terverifikasi',
        updatedAt: new Date().toISOString()
      }, { merge: true });
      showToast(`Sanksi suspend untuk Tukang #${tukangId} telah dicabut.`);
    } catch (e) {
      console.warn('Firestore unsuspendTukang error:', e);
      showToast('Gagal mencabut suspend. Coba lagi.', 'error');
    }
  };

  // Approve Withdrawal: update Firestore status
  const approveWithdrawal = async (withdrawId, adminNote) => {
    const note = adminNote || 'Disetujui dan ditransfer oleh Admin';
    const processedAt = new Date().toLocaleDateString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB';

    try {
      await setDoc(doc(db, 'withdrawals', withdrawId), {
        status: 'approved',
        processedAt,
        adminNote: note,
        updatedAt: new Date().toISOString()
      }, { merge: true });
      showToast(`Pencairan dana #${withdrawId} disetujui.`);
    } catch (e) {
      console.warn('Firestore approveWithdrawal error:', e);
      showToast('Gagal memperbarui pencairan dana. Coba lagi.', 'error');
    }
  };

  // Reject Withdrawal: update Firestore and refund balance
  const rejectWithdrawal = async (withdrawId, reason) => {
    const note = reason || 'Rekening tujuan tidak valid / nama tidak sesuai';

    try {
      const withdrawal = withdrawalsList.find(w => w.id === withdrawId);
      await setDoc(doc(db, 'withdrawals', withdrawId), {
        status: 'rejected',
        adminNote: note,
        updatedAt: new Date().toISOString()
      }, { merge: true });

      // Reversal: refund amount back to tukang wallet balance
      if (withdrawal && withdrawal.tukangId && withdrawal.amount > 0) {
        const tukangDoc = tukangList.find(t => t.id === withdrawal.tukangId);
        const currentBal = Number(tukangDoc?.walletBalance) || 0;
        await setDoc(doc(db, 'tukang', withdrawal.tukangId), {
          walletBalance: currentBal + Number(withdrawal.amount),
          updatedAt: new Date().toISOString()
        }, { merge: true });
      }

      showToast(`Pencairan dana #${withdrawId} ditolak. Saldo dikembalikan ke mitra.`, 'error');
    } catch (e) {
      console.warn('Firestore rejectWithdrawal error:', e);
      showToast('Gagal menolak pencairan dana. Coba lagi.', 'error');
    }
  };

  // Reset to demo mock data
  const resetDemoData = () => {
    if (!demoMode) {
      showToast('Reset Data Demo hanya tersedia dalam mode demo.', 'error');
      return;
    }
    setTukangList(initialTukangList);
    setUsersList(initialUsersList);
    setTicketsList(initialTicketsList);
    setWithdrawalsList(initialWithdrawalsList);
    showToast('Data demo berhasil di-reset ke kondisi awal!');
  };

  return (
    <AdminDataContext.Provider value={{
      tukangList,
      usersList,
      ticketsList,
      withdrawalsList,
      dataLoading,
      dataErrors,
      approveKyc,
      rejectKyc,
      suspendTukang,
      unsuspendTukang,
      approveWithdrawal,
      rejectWithdrawal,
      resetDemoData,
      isLiveConnected,
      toast
    }}>
      {children}
    </AdminDataContext.Provider>
  );
}

export function useAdminData() {
  const context = useContext(AdminDataContext);
  if (!context) {
    throw new Error('useAdminData must be used within an AdminDataProvider');
  }
  return context;
}
