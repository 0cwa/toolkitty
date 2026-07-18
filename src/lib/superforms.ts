import {
  zod as createZodAdapter,
  type ValidationAdapter,
  type ZodValidation,
} from "sveltekit-superforms/adapters";
import type { input, output, ZodTypeAny } from "zod/v3";

type FormOutput<T extends ZodTypeAny> =
  output<T> extends Record<string, unknown> ? output<T> : never;

type FormInput<T extends ZodTypeAny> =
  input<T> extends Record<string, unknown> ? input<T> : never;

/**
 * Keep form inference tied to the project's Zod v3 schemas.
 *
 * Superforms installs Zod v4 for its optional adapters, so its public Zod v3
 * adapter types can resolve against that package's compatibility layer instead
 * of the project's Zod v3 package. Both expose the same runtime schema API, but
 * their private generic types are not structurally identical.
 */
export function zod<T extends ZodTypeAny>(
  schema: T,
): ValidationAdapter<FormOutput<T>, FormInput<T>> {
  return createZodAdapter(
    schema as unknown as ZodValidation,
  ) as unknown as ValidationAdapter<FormOutput<T>, FormInput<T>>;
}
