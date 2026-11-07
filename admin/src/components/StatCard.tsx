import { LucideIcon } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: LucideIcon;
  trend?: string;
  trendUp?: boolean;
  color?: 'amber' | 'blue' | 'emerald' | 'purple';
}

export function StatCard({
  title,
  value,
  subtitle,
  icon: Icon,
  trend,
  trendUp = true,
  color = 'amber',
}: StatCardProps) {
  const colorMap = {
    amber: 'bg-camel-tint text-camel-dark border-camel/30',
    blue: 'bg-blue-50 text-blue-700 border-blue-200',
    emerald: 'bg-ok-bg text-ok border-ok-line',
    purple: 'bg-purple-50 text-purple-700 border-purple-200',
  };

  return (
    <div className="bg-panel border border-line rounded-2xl p-5 hover:border-line-strong transition-all duration-200 shadow-panel">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-ink-muted uppercase tracking-wider">{title}</span>
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center border ${colorMap[color]}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>

      <div className="mt-4 flex items-baseline justify-between">
        <span className="text-2xl font-bold text-ink tracking-tight">{value}</span>
        {trend && (
          <span
            className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
              trendUp ? 'bg-ok-bg text-ok' : 'bg-danger-bg text-danger'
            }`}
          >
            {trend}
          </span>
        )}
      </div>

      {subtitle && <p className="text-xs text-ink-muted mt-2 font-medium">{subtitle}</p>}
    </div>
  );
}
