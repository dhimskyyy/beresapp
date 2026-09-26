import React from 'react';
import { AlertTriangle, RotateCcw } from 'lucide-react';

export class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('ErrorBoundary caught an unhandled error:', error, errorInfo);
  }

  handleReload = () => {
    this.setState({ hasError: false, error: null });
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-[400px] flex items-center justify-center p-6">
          <div className="max-w-md w-full bg-white border border-rose-200 rounded-2xl p-6 shadow-sm text-center space-y-4">
            <div className="w-12 h-12 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center mx-auto">
              <AlertTriangle className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900">Terjadi Kesalahan Tampilan</h3>
              <p className="text-xs text-slate-500 mt-1">
                Halaman ini mengalami kendala saat merender data.
              </p>
            </div>
            {this.state.error && (
              <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl text-left">
                <p className="text-[11px] font-mono text-rose-700 break-words">
                  {this.state.error.message || String(this.state.error)}
                </p>
              </div>
            )}
            <button
              onClick={this.handleReload}
              className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-semibold transition-colors"
            >
              <RotateCcw className="w-4 h-4" />
              Muat Ulang Halaman
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
