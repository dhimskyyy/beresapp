import React, { createContext, useContext, useState, useEffect } from 'react';
import { initialTukangList, initialUsersList, initialTicketsList, initialWithdrawalsList } from '../data/mockData';

const AdminDataContext = createContext();

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

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 4000);
  };

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

  // KYC Approval
  const approveKyc = (tukangId) => {
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
    showToast(`KTP Tukang #${tukangId} berhasil disetujui. Akun mitra aktif!`);
  };

  // KYC Rejection
  const rejectKyc = (tukangId, reason) => {
    setTukangList(prev => prev.map(t => {
      if (t.id === tukangId) {
        return {
          ...t,
          verificationStatus: 'rejected',
          statusText: 'KTP Ditolak',
          isOnline: false,
          rejectionReason: reason || 'Dokumen KTP buram atau tidak sesuai.'
        };
      }
      return t;
    }));
    showToast(`KTP Tukang #${tukangId} ditolak. Notifikasi perbaikan dikirim.`, 'error');
  };

  // Suspend Tukang 3 Hari
  const suspendTukang = (tukangId, reason, days = 3) => {
    const suspendDurationMs = days * 24 * 60 * 60 * 1000;
    const suspendedUntil = new Date(Date.now() + suspendDurationMs).toISOString();

    setTukangList(prev => prev.map(t => {
      if (t.id === tukangId) {
        return {
          ...t,
          isSuspended: true,
          suspendedUntil,
          suspendReason: reason || 'Pelanggaran ketentuan layanan Beres',
          isOnline: false,
          statusText: `Suspended (${days} Hari)`
        };
      }
      return t;
    }));

    showToast(`Tukang #${tukangId} resmi disuspend selama ${days} hari!`, 'error');
  };

  // Lift Suspend Early (Cabut Suspend)
  const unsuspendTukang = (tukangId) => {
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
    showToast(`Sanksi suspend untuk Tukang #${tukangId} telah dicabut.`);
  };

  // Approve Withdrawal
  const approveWithdrawal = (withdrawId, adminNote) => {
    setWithdrawalsList(prev => prev.map(w => {
      if (w.id === withdrawId) {
        return {
          ...w,
          status: 'approved',
          processedAt: new Date().toLocaleDateString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB',
          adminNote: adminNote || 'Disetujui dan ditransfer oleh Admin'
        };
      }
      return w;
    }));
    showToast(`Pencairan dana #${withdrawId} disetujui.`);
  };

  // Reject Withdrawal
  const rejectWithdrawal = (withdrawId, reason) => {
    setWithdrawalsList(prev => prev.map(w => {
      if (w.id === withdrawId) {
        return {
          ...w,
          status: 'rejected',
          adminNote: reason || 'Rekening tujuan tidak valid / nama tidak sesuai'
        };
      }
      return w;
    }));
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
