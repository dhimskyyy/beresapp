import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AdminDataProvider } from './context/AdminDataContext';
import AdminLayout from './components/layout/AdminLayout';
import DashboardPage from './pages/DashboardPage';
import KycApprovalPage from './pages/KycApprovalPage';
import TukangMapPage from './pages/TukangMapPage';
import TukangListPage from './pages/TukangListPage';
import UserListPage from './pages/UserListPage';
import TicketMonitorPage from './pages/TicketMonitorPage';
import WithdrawalPage from './pages/WithdrawalPage';

export default function App() {
  return (
    <AdminDataProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<AdminLayout />}>
            <Route index element={<DashboardPage />} />
            <Route path="kyc" element={<KycApprovalPage />} />
            <Route path="live-map" element={<TukangMapPage />} />
            <Route path="tukang" element={<TukangListPage />} />
            <Route path="users" element={<UserListPage />} />
            <Route path="tickets" element={<TicketMonitorPage />} />
            <Route path="withdrawals" element={<WithdrawalPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AdminDataProvider>
  );
}
