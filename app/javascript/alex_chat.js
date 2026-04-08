// Alex Chat — Alpine.js component for AI chat interface

function alexChat() {
  return {
    messages: [],
    input: '',
    loading: false,
    messageId: 0,

    async sendMessage() {
      const text = this.input.trim();
      if (!text || this.loading) return;

      this.messages.push({ id: ++this.messageId, role: 'user', content: text });
      this.input = '';
      this.loading = true;
      this.scrollToBottom();

      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        const resp = await fetch('/chat', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ message: text })
        });

        const data = await resp.json();

        if (resp.ok) {
          this.messages.push({ id: ++this.messageId, role: 'assistant', content: data.response });
        } else {
          this.messages.push({ id: ++this.messageId, role: 'assistant', content: 'Sorry, something went wrong. Please try again.' });
        }
      } catch (err) {
        this.messages.push({ id: ++this.messageId, role: 'assistant', content: 'Connection error. Please try again.' });
      } finally {
        this.loading = false;
        this.scrollToBottom();
        this.$nextTick(() => this.$refs.input?.focus());
      }
    },

    formatMarkdown(text) {
      if (!text) return '';
      // Basic markdown: bold, italic, code, line breaks
      return text
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\*(.*?)\*/g, '<em>$1</em>')
        .replace(/`(.*?)`/g, '<code class="text-primary text-sm">$1</code>')
        .replace(/\n/g, '<br>');
    },

    scrollToBottom() {
      this.$nextTick(() => {
        const el = this.$refs.messages;
        if (el) el.scrollTop = el.scrollHeight;
      });
    }
  };
}

window.alexChat = alexChat;
