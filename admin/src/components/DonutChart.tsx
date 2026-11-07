'use client';

import React, { useState } from 'react';

export interface DonutSegment {
  id: string;
  label: string;
  value: number;
  color: string;
  count: number;
}

export interface DonutChartProps {
  title: string;
  subtitle: string;
  segments: DonutSegment[];
  size?: number;
  thickness?: number;
  totalLabel?: string;
}

export function DonutChart({
  title,
  subtitle,
  segments,
  size = 190,
  thickness = 24,
  totalLabel = '400 SP',
}: DonutChartProps) {
  const [hoveredId, setHoveredId] = useState<string | null>(null);

  const radius = (size - thickness) / 2;
  const circumference = 2 * Math.PI * radius;
  const totalValue = segments.reduce((sum, s) => sum + s.value, 0) || 1;

  const renderedSegments = segments.map((seg, index) => {
    const percent = seg.value / totalValue;
    const previousAccumulated = segments
      .slice(0, index)
      .reduce((sum, s) => sum + s.value / totalValue, 0);
    const strokeDasharray = `${circumference * percent} ${circumference * (1 - percent)}`;
    const strokeDashoffset = -circumference * previousAccumulated;

    return {
      ...seg,
      percent: Math.round(percent * 100),
      strokeDasharray,
      strokeDashoffset,
    };
  });

  const activeSegment = hoveredId
    ? renderedSegments.find((s) => s.id === hoveredId)
    : null;

  return (
    <div className="p-6 rounded-2xl bg-panel border border-line hover:border-line-strong transition-all duration-300 shadow-panel">
      <div className="mb-4">
        <h3 className="font-bold text-ink text-base">{title}</h3>
        <p className="text-xs text-ink-muted mt-0.5">{subtitle}</p>
      </div>

      <div className="flex flex-col md:flex-row items-center gap-8 justify-between pt-2">
        {/* SVG Donut */}
        <div className="relative flex items-center justify-center shrink-0">
          <svg width={size} height={size} className="rotate-[-90deg]">
            <circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              stroke="currentColor"
              strokeWidth={thickness}
              className="text-tint"
              fill="transparent"
            />

            {renderedSegments.map((seg) => {
              const isHovered = hoveredId === seg.id;
              return (
                <circle
                  key={seg.id}
                  cx={size / 2}
                  cy={size / 2}
                  r={radius}
                  stroke={seg.color}
                  strokeWidth={isHovered ? thickness + 4 : thickness}
                  strokeDasharray={seg.strokeDasharray}
                  strokeDashoffset={seg.strokeDashoffset}
                  fill="transparent"
                  className="transition-all duration-300 cursor-pointer"
                  onMouseEnter={() => setHoveredId(seg.id)}
                  onMouseLeave={() => setHoveredId(null)}
                />
              );
            })}
          </svg>

          {/* Center Info */}
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center pointer-events-none">
            {activeSegment ? (
              <>
                <span
                  className="text-2xl font-extrabold font-mono transition-colors"
                  style={{ color: activeSegment.color }}
                >
                  {activeSegment.count} SP
                </span>
                <span className="text-[11px] font-semibold text-ink-mid line-clamp-1 max-w-[120px]">
                  {activeSegment.percent}% cơ cấu
                </span>
              </>
            ) : (
              <>
                <span className="text-2xl font-extrabold text-ink font-mono tracking-tight">
                  {totalLabel}
                </span>
                <span className="text-[10px] font-medium text-ink-muted uppercase tracking-wider">
                  {segments.length} Danh mục
                </span>
              </>
            )}
          </div>
        </div>

        {/* Legend List */}
        <div className="flex-1 w-full grid grid-cols-1 sm:grid-cols-2 gap-2.5">
          {renderedSegments.map((seg) => {
            const isHovered = hoveredId === seg.id;
            return (
              <div
                key={seg.id}
                onMouseEnter={() => setHoveredId(seg.id)}
                onMouseLeave={() => setHoveredId(null)}
                className={`flex items-center justify-between p-2.5 rounded-xl transition-all cursor-pointer ${
                  isHovered ? 'bg-camel-tint scale-[1.02]' : 'bg-tint hover:bg-camel-tint/60'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <span
                    className="w-3 h-3 rounded-full shrink-0 shadow-sm"
                    style={{ backgroundColor: seg.color }}
                  />
                  <span className="text-xs font-semibold text-ink-mid">{seg.label}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold font-mono text-ink">{seg.count} sp</span>
                  <span className="text-[11px] font-mono text-ink-muted bg-panel px-1.5 py-0.5 rounded-md border border-line">
                    {seg.percent}%
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
