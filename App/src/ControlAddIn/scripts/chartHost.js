window.RenderBarChart = function (chartJson) {
    const root = document.getElementById('controlAddIn');
    if (!root) return;
    root.replaceChildren();

    let payload;
    try { payload = JSON.parse(chartJson || '{}'); } catch { payload = {}; }
    const toNum = (v) => (v === null || v === undefined ? NaN : Number(v));
    const labels = Array.isArray(payload.labels) ? payload.labels : [];
    const s1 = Array.isArray(payload.series1) ? payload.series1.map(toNum) : [];
    const s2 = Array.isArray(payload.series2) ? payload.series2.map(toNum) : [];

    if (!labels.length) {
        const empty = document.createElement('div');
        empty.className = 'mbs-empty';
        empty.textContent = payload.emptyMessage || 'No data for selected period.';
        root.appendChild(empty);
        return;
    }

    const numericValues = [...s1, ...s2].filter((v) => Number.isFinite(v)).map((v) => Math.abs(v));
    const maxVal = Math.max(1, ...numericValues);

    const chart = document.createElement('div');
    chart.className = 'mbs-chart';

    const header = document.createElement('div');
    header.className = 'mbs-header';
    const title = document.createElement('span');
    title.className = 'mbs-title';
    title.textContent = payload.title || '';
    header.appendChild(title);
    chart.appendChild(header);

    if (payload.series1Label || payload.series2Label) {
        const legend = document.createElement('div');
        legend.className = 'mbs-legend';
        [[payload.series1Label, 's1'], [payload.series2Label, 's2']].forEach(([text, cls]) => {
            if (!text) return;
            const item = document.createElement('span');
            item.className = 'mbs-legend-item';
            const swatch = document.createElement('span');
            swatch.className = 'mbs-swatch ' + cls;
            item.appendChild(swatch);
            item.appendChild(document.createTextNode(String(text)));
            legend.appendChild(item);
        });
        chart.appendChild(legend);
    }

    labels.forEach((lbl, i) => {
        const row = document.createElement('div');
        row.className = 'mbs-row';

        const labelEl = document.createElement('div');
        labelEl.className = 'mbs-label';
        labelEl.textContent = String(lbl);
        labelEl.title = String(lbl);
        row.appendChild(labelEl);

        const bars = document.createElement('div');
        bars.className = 'mbs-bars';

        [s1[i], s2[i]].forEach((val, idx) => {
            if (!Number.isFinite(val)) return;
            const bar = document.createElement('div');
            bar.className = 'mbs-bar ' + (idx === 0 ? 's1' : 's2') + (val < 0 ? ' neg' : '');
            bar.style.width = Math.round((Math.abs(val) / maxVal) * 100) + '%';
            const seriesName = idx === 0 ? (payload.series1Label || '') : (payload.series2Label || '');
            bar.title = seriesName + ': ' + val;
            bars.appendChild(bar);
        });

        row.appendChild(bars);
        chart.appendChild(row);
    });

    root.appendChild(chart);
};
