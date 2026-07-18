import { describe, expect, test } from "vitest";
import {
  normalizeAvailabilityForForm,
  normalizeLinkForForm,
  resourceSchema,
} from "$lib/schemas";

const resourceFields = {
  name: "Projector",
  description: "Portable projector",
  contact: "coordinator@example.com",
  images: [],
  multiBookable: false,
};

describe("resource form normalization", () => {
  test("requires an end for each bounded availability", () => {
    const result = resourceSchema.safeParse({
      ...resourceFields,
      availability: [{ start: "2025-03-01T10:00Z" }],
    });

    expect(result.success).toBe(false);
  });

  test("represents incomplete persisted availability as an editable value", () => {
    const availability = normalizeAvailabilityForForm([
      { start: "2025-03-01T10:00Z" },
    ]);

    expect(availability).toEqual([{ start: "2025-03-01T10:00Z", end: "" }]);
    expect(
      resourceSchema.safeParse({
        ...resourceFields,
        availability,
      }).success,
    ).toBe(false);
  });

  test("initializes an editable link when the record has none", () => {
    expect(normalizeLinkForForm()).toEqual({
      title: "",
      type: "custom",
      url: "",
    });
  });
});
