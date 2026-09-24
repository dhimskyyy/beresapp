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
    verificationStatus: docData.verificationStatus || 'verified',
    statusText: docData.statusText || (docData.isOnline ? 'Online / Siap Kerja' : 'Offline'),
    services: docData.services || [],
    payoutAccounts: docData.payoutAccounts || [],
    isSuspended: Boolean(docData.isSuspended),
    walletBalance: docData.walletBalance || 0,
    rating: docData.rating || 5.0,
    reviewCount: docData.reviewCount || 0,
  };
};

const mergeTickets = (cloudDocs, fallbackList) => {
  const mergedMap = new Map();
  for (const item of fallbackList) {
    mergedMap.set(item.id, item);
  }
  for (const item of cloudDocs) {
    mergedMap.set(item.id, normalizeTicket(item, item.id));
  }
  return Array.from(mergedMap.values()).sort((a, b) => {
    const timeA = new Date(a.createdAt || 0).getTime();
    const timeB = new Date(b.createdAt || 0).getTime();
    return timeB - timeA;
  });
};

const mergeTukang = (cloudDocs, fallbackList) => {
  const mergedMap = new Map();
  for (const item of fallbackList) {
    mergedMap.set(item.id, item);
  }
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

const mergeWithdrawals = (cloudDocs, fallbackList) => {
  const mergedMap = new Map();
  for (const item of fallbackList) {
    mergedMap.set(item.id, normalizeWithdrawal(item, item.id));
  }
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
  const [tukangList, setTukangList] = useState(() => {
    const saved = localStorage.getItem('beres_admin_tukang');
    return saved ? JSON.parse(saved) : initialTukangList;
  });

  const [usersList, setUsersList] = useState(() => {
    const saved = localStorage.getItem('beres_admin_users');
    return saved ? JSON.parse(saved) : initialUsersList;
  });

  const [ticketsList, setTicketsList] = useState(() => {
    const saved = localStorage.getItem('beres_admin_tickets');
    return saved ? JSON.parse(saved) : initialTicketsList;
  });

  const [withdrawalsList, setWithdrawalsList] = useState(() => {
    const saved = localStorage.getItem('beres_admin_withdrawals');
    return saved ? JSON.parse(saved) : initialWithdrawalsList;
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
        if (!snapshot.empty) {
          const docs = snapshot.docs.map(d => ({ ...d.data(), id: d.id }));
          setTicketsList(() => mergeTickets(docs, initialTicketsList));
        }
      }, (error) => {
        console.warn('Firestore tickets realtime listener notice:', error);
      });
    } catch (e) {
      console.warn('Firestore tickets setup notice:', e);
    }
    return () => unsubscribe && unsubscribe();
  }, []);

  // 2. Sync with Cloud Firestore Realtime: tukang collection
  useEffect(() => {
    let unsubscribe;
    try {
      unsubscribe = onSnapshot(collection(db, 'tukang'), (snapshot) => {
        setIsLiveConnected(true);
        if (!snapshot.empty) {
          const docs = snapshot.docs.map(d => ({ ...d.data(), id: d.id }));
          setTukangList(() => mergeTukang(docs, initialTukangList));
        }
      }, (error) => {
        console.warn('Firestore tukang realtime listener notice:', error);
      });
    } catch (e) {
      console.warn('Firestore tukang setup notice:', e);
    }
    return () => unsubscribe && unsubscribe();
  }, []);

  // 3. Sync with Cloud Firestore Realtime: withdrawals collection
  useEffect(() => {
    let unsubscribe;
    try {
      unsubscribe = onSnapshot(collection(db, 'withdrawals'), (snapshot) => {
        setIsLiveConnected(true);
        if (!snapshot.empty) {
          const docs = snapshot.docs.map(d => ({ ...d.data(), id: d.id }));
          setWithdrawalsList(() => mergeWithdrawals(docs, initialWithdrawalsList));
        }
      }, (error) => {
        console.warn('Firestore withdrawals realtime listener notice:', error);
      });
    } catch (e) {
      console.warn('Firestore withdrawals setup notice:', e);
    }
    return () => unsubscribe && unsubscribe();
  }, []);

  // Save to local cache
  useEffect(() => {
    localStorage.setItem('beres_admin_tukang', JSON.stringify(tukangList));
  }, [tukangList]);

  useEffect(() => {
    localStorage.setItem('beres_admin_users', JSON.stringify(usersList));
  }, [usersList]);

  useEffect(() => {
    localStorage.setItem('beres_admin_tickets', JSON.stringify(ticketsList));
  }, [ticketsList]);

  useEffect(() => {
    localStorage.setItem('beres_admin_withdrawals', JSON.stringify(withdrawalsList));
  }, [withdrawalsList]);

  // KYC Approval: update state and Firestore
  const approveKyc = async (tukangId) => {
    setTukangList(prev => prev.map(t => {
      if (t.id === tukangId) {
        return {
          ...t,
          verificationStatus: 'verified',
          statusText: 'Online / Siap Kerja',
          isOnline: true,
          rejectionReason: null
        };
      }
      return t;
    }));

    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        verificationStatus: 'verified',
        statusText: 'Online / Siap Kerja',
        isOnline: true,
        rejectionReason: null,
        updatedAt: new Date().toISOString()
      }, { merge: true });
    } catch (e) {
      console.warn('Firestore approveKyc error:', e);
    }

    showToast(`Pendaftaran Mitra #${tukangId} berhasil disetujui. Akun mitra aktif!`);
  };

  // KYC Rejection: update state and Firestore
  const rejectKyc = async (tukangId, reason) => {
    const finalReason = reason || 'Keahlian atau kontak belum memenuhi kriteria.';
    setTukangList(prev => prev.map(t => {
      if (t.id === tukangId) {
        return {
          ...t,
          verificationStatus: 'rejected',
          statusText: 'Pendaftaran Ditolak',
          isOnline: false,
          rejectionReason: finalReason
        };
      }
      return t;
    }));

    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        verificationStatus: 'rejected',
        statusText: 'Pendaftaran Ditolak',
        isOnline: false,
        rejectionReason: finalReason,
        updatedAt: new Date().toISOString()
      }, { merge: true });
    } catch (e) {
      console.warn('Firestore rejectKyc error:', e);
    }

    showToast(`Pendaftaran Mitra #${tukangId} ditolak. Notifikasi perbaikan dikirim.`, 'error');
  };

  // Suspend Tukang 3 Hari
  const suspendTukang = async (tukangId, reason, days = 3) => {
    const suspendDurationMs = days * 24 * 60 * 60 * 1000;
    const suspendedUntil = new Date(Date.now() + suspendDurationMs).toISOString();
    const finalReason = reason || 'Pelanggaran ketentuan layanan Beres';

    setTukangList(prev => prev.map(t => {
      if (t.id === tukangId) {
        return {
          ...t,
          isSuspended: true,
          suspendedUntil,
          suspendReason: finalReason,
          isOnline: false,
          statusText: `Suspended (${days} Hari)`
        };
      }
      return t;
    }));

    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        isSuspended: true,
        suspendedUntil,
        suspendReason: finalReason,
        isOnline: false,
        statusText: `Suspended (${days} Hari)`,
        updatedAt: new Date().toISOString()
      }, { merge: true });
    } catch (e) {
      console.warn('Firestore suspendTukang error:', e);
    }

    showToast(`Tukang #${tukangId} resmi disuspend selama ${days} hari!`, 'error');
  };

  // Lift Suspend Early (Cabut Suspend)
  const unsuspendTukang = async (tukangId) => {
    setTukangList(prev => prev.map(t => {
      if (t.id === tukangId) {
        return {
          ...t,
          isSuspended: false,
          suspendedUntil: null,
          suspendReason: null,
          statusText: 'Online / Siap Kerja',
          isOnline: true
        };
      }
      return t;
    }));

    try {
      await setDoc(doc(db, 'tukang', tukangId), {
        isSuspended: false,
        suspendedUntil: null,
        suspendReason: null,
        statusText: 'Online / Siap Kerja',
        isOnline: true,
        updatedAt: new Date().toISOString()
      }, { merge: true });
    } catch (e) {
      console.warn('Firestore unsuspendTukang error:', e);
    }

    showToast(`Sanksi suspend untuk Tukang #${tukangId} telah dicabut.`);
  };

  // Approve Withdrawal: update state and Firestore
  const approveWithdrawal = async (withdrawId, adminNote) => {
    const note = adminNote || 'Disetujui dan ditransfer oleh Admin';
    const processedAt = new Date().toLocaleDateString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB';

    setWithdrawalsList(prev => prev.map(w => {
      if (w.id === withdrawId) {
        return {
          ...w,
          status: 'approved',
          processedAt,
          adminNote: note
        };
      }
      return w;
    }));

    try {
      await setDoc(doc(db, 'withdrawals', withdrawId), {
        status: 'approved',
        processedAt,
        adminNote: note,
        updatedAt: new Date().toISOString()
      }, { merge: true });
    } catch (e) {
      console.warn('Firestore approveWithdrawal error:', e);
    }

    showToast(`Pencairan dana #${withdrawId} disetujui.`);
  };

  // Reject Withdrawal: update state and Firestore
  const rejectWithdrawal = async (withdrawId, reason) => {
    const note = reason || 'Rekening tujuan tidak valid / nama tidak sesuai';

    setWithdrawalsList(prev => prev.map(w => {
      if (w.id === withdrawId) {
        return {
          ...w,
          status: 'rejected',
          adminNote: note
        };
      }
      return w;
    }));

    try {
      await setDoc(doc(db, 'withdrawals', withdrawId), {
        status: 'rejected',
        adminNote: note,
        updatedAt: new Date().toISOString()
      }, { merge: true });
    } catch (e) {
      console.warn('Firestore rejectWithdrawal error:', e);
    }

    showToast(`Pencairan dana #${withdrawId} ditolak.`, 'error');
  };

  // Reset to demo mock data
  const resetDemoData = () => {
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
