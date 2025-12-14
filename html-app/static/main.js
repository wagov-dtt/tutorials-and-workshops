import Alpine from 'alpinejs';
import { table } from 'arquero';

export const app = {
  start() {
    document.addEventListener('alpine:init', () => {
      Alpine.data('crud', () => ({
        view: 'list',
        dt: table({ id: [0, 1, 2], name: ['Item 0', 'Item 1', 'Item 2'] }),
        form: { name: '', testLoadCount: 10000 },

        get tableHTML() {
          return this.dt.toHTML({ limit: 10000000 });
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
          const rows = this.dt.objects();
          const startId = rows.length ? Math.max(...rows.map(r => r.id)) + 1 : 0;
          const count = Math.max(1, parseInt(this.form.testLoadCount) || 10000);
          const newIds = Array.from({ length: count }, (_, i) => startId + i);
          const newNames = newIds.map(i => `Item ${i}`);
          const allIds = [...rows.map(r => r.id), ...newIds];
          const allNames = [...rows.map(r => r.name), ...newNames];
          this.dt = table({ id: allIds, name: allNames });
        }
      }));
    });
    Alpine.start();
  }
}
