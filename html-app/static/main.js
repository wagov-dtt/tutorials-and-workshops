import Alpine from "alpinejs";
import { table } from "arquero";

export const app = {
  start() {
    document.addEventListener("alpine:init", () => {
      Alpine.data("crud", () => ({
        view: "Items",
        itemsView: "list",
        search: "",
        dt: table({
          id: [0, 1, 2],
          name: ["Item 0", "Item 1", "Item 2"],
          description: [
            "<strong>Lorem ipsum</strong> dolor sit amet, <em>consectetur adipiscing</em> elit.",
            "Sed do <strong>eiusmod tempor</strong> incididunt ut labore et <em>dolore magna</em> aliqua.",
            "Ut enim ad <strong>minim veniam</strong>, <em>quis nostrud</em> exercitation ullamco.",
          ],
        }),
        form: { name: "", description: "", testLoadCount: 10000 },

        get filteredItems() {
          const query = this.search.toLowerCase();
          if (!query) return this.dt.objects();
          return this.dt
            .objects()
            .filter(
              (item) =>
                item.name.toLowerCase().includes(query) ||
                item.description.toLowerCase().includes(query),
            );
        },

        get nextId() {
          const rows = this.dt.objects();
          return rows.length ? Math.max(...rows.map((r) => r.id)) + 1 : 0;
        },

        saveItem() {
          const rows = this.dt.objects();
          rows.push({
            id: this.nextId,
            name: this.form.name,
            description: this.form.description || "No description provided.",
          });
          this.dt = table({
            id: rows.map((r) => r.id),
            name: rows.map((r) => r.name),
            description: rows.map((r) => r.description),
          });
          this.form.name = "";
          this.form.description = "";
          this.view = "Items";
        },

        clearAll() {
          this.dt = table({ id: [], name: [], description: [] });
        },

        testLoad() {
          const rows = this.dt.objects();
          const startId = rows.length
            ? Math.max(...rows.map((r) => r.id)) + 1
            : 0;
          const count = Math.max(1, parseInt(this.form.testLoadCount) || 10000);
          const newIds = Array.from({ length: count }, (_, i) => startId + i);
          const newNames = newIds.map((i) => `Item ${i}`);
          const newDescriptions = newIds.map(
            (i) =>
              "<strong>Lorem ipsum</strong> dolor sit amet, <em>consectetur adipiscing</em> elit.",
          );
          const allIds = [...rows.map((r) => r.id), ...newIds];
          const allNames = [...rows.map((r) => r.name), ...newNames];
          const allDescriptions = [
            ...rows.map((r) => r.description),
            ...newDescriptions,
          ];
          this.dt = table({
            id: allIds,
            name: allNames,
            description: allDescriptions,
          });
        },
      }));
    });
    Alpine.start();
  },
};
