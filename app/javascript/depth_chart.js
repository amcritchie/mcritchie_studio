// DepthChart manager — Alpine component for /teams/:slug/depth-chart
// Wires SortableJS for drag-reorder within a position and POSTs reorder + lock toggles.

function depthChart(reorderUrl) {
  return {
    csrf() {
      return document.querySelector('meta[name="csrf-token"]')?.content;
    },

    init() {
      this.$nextTick(() => this.initSortables());
    },

    initSortables() {
      document.querySelectorAll('.dc-zone').forEach(zone => {
        Sortable.create(zone, {
          animation: 150,
          handle: '.dc-handle',
          filter: '.dc-locked',
          preventOnFilter: false,
          onMove: (evt) => !evt.related.classList.contains('dc-locked'),
          onEnd: (evt) => this.handleSort(evt)
        });
      });
    },

    async handleSort(evt) {
      const zone = evt.to;
      const position = zone.dataset.position;
      const entry_ids = Array.from(zone.querySelectorAll('.dc-entry')).map(li => li.dataset.id);
      try {
        const resp = await fetch(reorderUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this.csrf() },
          body: JSON.stringify({ position, entry_ids })
        });
        if (!resp.ok) throw new Error('reorder failed');
        zone.querySelectorAll('.dc-entry').forEach((li, i) => {
          li.querySelector('.font-mono.w-5').textContent = i + 1;
        });
      } catch (e) {
        console.error(e);
        alert('Reorder failed — refresh and try again.');
      }
    },

    async toggleLock(id, btn) {
      try {
        const resp = await fetch('/depth_chart_entries/' + id + '/toggle_lock', {
          method: 'POST',
          headers: { 'X-CSRF-Token': this.csrf() }
        });
        if (!resp.ok) throw new Error('lock failed');
        const data = await resp.json();
        const li = btn.closest('.dc-entry');
        li.classList.toggle('dc-locked', data.locked);
        li.dataset.locked = data.locked;
        const span = btn.querySelector('span');
        span.dataset.label = data.locked ? '🔒' : '🔓';
        span.textContent = data.locked ? '🔒' : '🔓';
      } catch (e) {
        console.error(e);
        alert('Lock toggle failed.');
      }
    }
  };
}

window.depthChart = depthChart;
