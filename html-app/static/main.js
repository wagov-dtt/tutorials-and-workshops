import Alpine from 'alpinejs';
import { table } from 'arquero';

export const app = {
  start() {
    document.addEventListener('alpine:init', () => {
      Alpine.data('crud', () => ({
        view: 'list',
        dt: table({ id: [0, 1, 2], name: ['Item 0', 'Item 1', 'Item 2'] }),
        form: { name: '' },

        get tableHTML() {
          return this.dt.toHTML();
        },

        get nextId() {
          const rows = this.dt.objects();
          return rows.length ? Math.max(...rows.map(r => r.id)) + 1 : 0;
        },

        saveItem() {
          const rows = this.dt.objects();
          rows.push({ id: this.nextId, name: this.form.name });
          this.dt = table({ id: rows.map(r => r.id), name: rows.map(r => r.name) });
          this.form.name = '';
          this.view = 'list';
        },

        clearAll() {
          this.dt = table({ id: [], name: [] });
        },

        testLoad() {
          const n = 100000;
          const ids = Array.from({ length: n }, (_, i) => i);
          const names = ids.map(i => `Item ${i}`);
          this.dt = table({ id: ids, name: names });
        }
      }));
    });
    Alpine.start();
  }
}
