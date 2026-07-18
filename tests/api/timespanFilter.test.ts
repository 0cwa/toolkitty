// This is required to mock the indexedDB API and must be imported at the top of the module.
import "fake-indexeddb/auto";

import { processMessage } from "$lib/processor";
import { CALENDAR_ID } from "$lib/utils/faker";
import { seedTestMessages } from "./data";
import { setupSeedTestIPC } from "./setup";
import { resources, spaces } from "$lib/api";
import { beforeAll, describe, expect, test } from "vitest";
import { TimeSpanClass } from "$lib/timeSpan";

setupSeedTestIPC();

beforeAll(async () => {
  for (const message of seedTestMessages()) {
    await processMessage(message);
  }
});

describe("timespan filter queries", () => {
  test("filter spaces by timespan", async () => {
    let spacesCollection = await spaces.findByTimeSpan(
      CALENDAR_ID,
      new TimeSpanClass({
        start: "2025-03-01T09:00:00Z",
        end: "2025-04-01T09:00:00Z",
      }),
    );
    expect(spacesCollection.length).toBe(1);
    spacesCollection = await spaces.findByTimeSpan(
      CALENDAR_ID,
      new TimeSpanClass({
        start: "2025-05-01T09:00:00Z",
        end: "2025-05-01T09:00:00Z",
      }),
    );
    expect(spacesCollection.length).toBe(0);
  });

  test("filter resources by timespan", async () => {
    // The seed data resources is available "always" so it will be returned by any query.
    let resourcesCollection = await resources.findByTimeSpan(
      CALENDAR_ID,
      new TimeSpanClass({
        start: "2025-03-01T09:00:00Z",
        end: "2025-04-01T09:00:00Z",
      }),
    );
    expect(resourcesCollection.length).toBe(1);
    resourcesCollection = await resources.findByTimeSpan(
      CALENDAR_ID,
      new TimeSpanClass({
        start: "2025-05-01T09:00:00Z",
        end: "2025-05-01T09:00:00Z",
      }),
    );
    expect(resourcesCollection.length).toBe(1);
  });
});
