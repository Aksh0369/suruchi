import { badRequest } from '../lib/errors.js';

/**
 * validate({ body: schema, query: schema, params: schema })
 *
 * Replaces req.body/query/params with the parsed result so handlers get
 * coerced, trimmed values rather than raw strings.
 */
export function validate(schemas) {
  return (req, _res, next) => {
    for (const part of ['params', 'query', 'body']) {
      const schema = schemas[part];
      if (!schema) continue;

      const result = schema.safeParse(req[part]);
      if (!result.success) {
        const details = result.error.issues.map((issue) => ({
          field: issue.path.join('.') || part,
          message: issue.message,
        }));
        return next(badRequest('Some fields need fixing', details));
      }
      req[part] = result.data;
    }
    next();
  };
}
