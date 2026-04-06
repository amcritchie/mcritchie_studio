// Kanban board — drag-and-drop task management
// Extracted from tasks/index.html.erb inline script

function kanbanBoard() {
  return {
    draggedSlug: null,
    draggedStage: null,
    dropTarget: null,
    agentFilter: '',
    showArchived: false,
    toasts: [],

    stageLabels: {
      new: 'New', queued: 'Queued', in_progress: 'In Progress',
      done: 'Done', failed: 'Failed', archived: 'Archived'
    },

    transitions: {
      new:         { queued: 'queue' },
      queued:      { in_progress: 'start', failed: 'fail_task' },
      in_progress: { done: 'complete', failed: 'fail_task' },
      done:        { archived: 'archive' },
      failed:      { archived: 'archive', queued: 'queue' }
    },

    matchesFilter(agent) {
      return !this.agentFilter || agent === this.agentFilter;
    },

    startDrag(event, slug, stage) {
      this.draggedSlug = slug;
      this.draggedStage = stage;
      event.dataTransfer.effectAllowed = 'move';
    },

    endDrag() {
      this.draggedSlug = null;
      this.draggedStage = null;
      this.dropTarget = null;
    },

    updateCounts() {
      document.querySelectorAll('[data-stage-count]').forEach(badge => {
        const stage = badge.dataset.stageCount;
        const zone = document.getElementById('dropzone-' + stage);
        if (zone) {
          const count = zone.querySelectorAll('.kanban-card').length;
          badge.textContent = count;
          const empty = zone.querySelector('.kanban-empty');
          if (empty) empty.style.display = count === 0 ? 'flex' : 'none';
        }
      });
    },

    async dropCard(newStage) {
      this.dropTarget = null;
      if (!this.draggedSlug || this.draggedStage === newStage) return;

      const slug = this.draggedSlug;
      const oldStage = this.draggedStage;
      const card = document.getElementById('card-' + slug);
      const newZone = document.getElementById('dropzone-' + newStage);
      const oldZone = document.getElementById('dropzone-' + oldStage);

      if (!card || !newZone) return;

      // Optimistic DOM move
      newZone.insertBefore(card, newZone.querySelector('.kanban-empty'));
      card.dataset.stage = newStage;
      this.updateCounts();

      // Determine API call
      const transitionName = this.transitions[oldStage]?.[newStage];
      let url, method, body;

      if (transitionName) {
        url = '/api/v1/tasks/' + slug + '/' + transitionName;
        method = 'POST';
      } else {
        url = '/api/v1/tasks/' + slug;
        method = 'PATCH';
        body = JSON.stringify({ stage: newStage });
      }

      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        const resp = await fetch(url, {
          method,
          headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
          body: body || undefined
        });

        if (!resp.ok) {
          const err = await resp.json().catch(() => ({}));
          throw new Error(err.error || 'Failed (' + resp.status + ')');
        }

        this.showToast('Task moved to ' + this.stageLabels[newStage], 'success');
      } catch (err) {
        // Revert
        if (oldZone) {
          oldZone.insertBefore(card, oldZone.querySelector('.kanban-empty'));
          card.dataset.stage = oldStage;
          this.updateCounts();
        }
        card.classList.add('ring-2', 'ring-red-500');
        setTimeout(() => card.classList.remove('ring-2', 'ring-red-500'), 1500);
        this.showToast(err.message || 'Move failed', 'error');
      }
    },

    async archiveTask(slug) {
      const card = document.getElementById('card-' + slug);
      const oldStage = card?.dataset.stage;
      const archivedZone = document.getElementById('dropzone-archived');

      if (card && archivedZone) {
        archivedZone.insertBefore(card, archivedZone.querySelector('.kanban-empty'));
        card.dataset.stage = 'archived';
        this.updateCounts();
      }

      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        const resp = await fetch('/api/v1/tasks/' + slug + '/archive', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken }
        });
        if (!resp.ok) throw new Error('Archive failed');
        this.showToast('Task archived', 'success');
      } catch (err) {
        // Revert
        if (card && oldStage) {
          const oldZone = document.getElementById('dropzone-' + oldStage);
          if (oldZone) {
            oldZone.insertBefore(card, oldZone.querySelector('.kanban-empty'));
            card.dataset.stage = oldStage;
            this.updateCounts();
          }
        }
        this.showToast(err.message, 'error');
      }
    },

    async deleteTask(slug) {
      if (!confirm('Delete this task?')) return;
      const card = document.getElementById('card-' + slug);

      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        const resp = await fetch('/api/v1/tasks/' + slug, {
          method: 'DELETE',
          headers: { 'X-CSRF-Token': csrfToken }
        });
        if (!resp.ok) throw new Error('Delete failed');
        if (card) card.remove();
        this.updateCounts();
        this.showToast('Task deleted', 'success');
      } catch (err) {
        this.showToast(err.message, 'error');
      }
    },

    showToast(message, type) {
      const id = Date.now();
      const toast = { id, message, type, visible: true };
      this.toasts.push(toast);
      setTimeout(() => {
        const t = this.toasts.find(t => t.id === id);
        if (t) t.visible = false;
        setTimeout(() => { this.toasts = this.toasts.filter(t => t.id !== id); }, 300);
      }, 3000);
    }
  }
}

// Attach to window for Alpine x-data access
window.kanbanBoard = kanbanBoard;
