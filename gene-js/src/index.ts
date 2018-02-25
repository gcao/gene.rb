namespace Gene {
  export class Base {

    public static from_data(data: any[]) {
      const obj = new Gene.Base();
      obj.data = data;

      return obj;
    }

    public class: any;
    public properties: object;

    constructor(_class: any = Base) {
      this.class = _class;
      this.properties = {};
    }

    public get(name: any) {
      if (typeof name === 'string') {
        return this.properties[name];
      } else {
        return this.data[name];
      }
    }

    public set(name: string, value: any) {
      this.properties[name] = value;
    }

    get data() {
      return this.get('#data');
    }
    set data(data: any[]) {
      this.set('#data', data);
    }

    public as(klass: any): any {
      const obj = new Base(klass);
      obj.properties = this.properties;

      return obj;
    }
  }

  export class Module extends Base {
    constructor(name: string) {
      super(Module);
      this.name = name;
    }

    get name(): string {
      return this.get('name');
    }
    set name(new_name: string) {
      this.set('name', new_name);
    }

    get methods(): [any] {
      return this.get('methods');
    }
    set methods(new_methods: [any]) {
      this.set('methods', new_methods);
    }

    get prop_descriptors(): object {
      return this.get('prop_descriptors');
    }
    set prop_descriptors(new_descriptors: object) {
      this.set('prop_descriptors', new_descriptors);
    }

    get modules() {
      return this.get('modules');
    }
    set modules(new_modules: [any]) {
      this.set('modules', new_modules);
    }

    public method(name: string) {
      return this.methods[name];
    }
  }

  export class Class extends Module {
    constructor(name: string) {
      super(name);
      this.class = Class;
    }
  }

  export class Namespace extends Base {
    constructor(name: string, parent: Namespace) {
      super(Namespace);
      this.set('name', name);
      this.set('parent', parent);
      this.set('members', {});
      this.set('public_members', []);
    }

    get members() {
      return this.get('members');
    }

    public is_defined(name: string): boolean {
      return this.members.hasOwnProperty(name);
    }

    public get_member(name: string) {
      return this.members[name];
    }

    public set_member(name: string, value: any) {
      this.members[name] = value;
    }

    public ['var'](name: string, value: any) {
      this.members[name] = value;
    }
  }

  export class Application extends Base {
    constructor() {
      super(Application);
      this.set('global_namespace', new Namespace('global', null));
    }

    get global_namespace() {
      return this.get('global_namespace');
    }

    public create_root_context(): Context {
      const context = new Context(this);
      context.namespace = new Namespace('root', this.global_namespace);
      context.self = context.namespace;
      context.scope = new Scope(undefined, false);

      return context;
    }
  }

  export class Context extends Base {
    constructor(application: Application) {
      super(Context);
      this.set('application', application);
    }

    get application() {
      return this.get('application');
    }

    get global_namespace() {
      return this.application.global_namespace;
    }

    get namespace() {
      return this.get('namespace');
    }

    set namespace(new_namespace: Namespace) {
      this.set('namespace', new_namespace);
    }

    get scope() {
      return this.get('scope');
    }

    set scope(new_scope: Scope) {
      this.set('scope', new_scope);
    }

    get self() {
      return this.get('self');
    }

    set self(new_self: any) {
      this.set('self', new_self);
    }

    public extend(options: any): Context {
      const new_context = new Context(this.application);
      if (options.namespace) {
        new_context.namespace = options.namespace;
      }
      if (options.scope) {
        new_context.scope = options.scope;
      }
      if (options.self) {
        new_context.self = options.self;
      }

      return new_context;
    }

    public get_member(name: string) {
      if (this.scope && this.scope.is_defined(name)) {
        return this.scope.get_member(name);
      } else if (this.namespace && this.namespace.is_defined(name)) {
        return this.namespace.get_member(name);
      } else if (this.global_namespace.is_defined(name)) {
        return this.global_namespace.get_member(name);
      } else {
        // throw new Error(`${name} is not defined.`);
        throw `${name} is not defined.`;
      }
    }

    public set_member(name: string, value: any) {
      this.scope.set_member(name, value);
    }

    // Helper methods

    public ['var'](name: string, value: any) {
      if (this.scope) {
        this.scope.set_member(name, value);
      } else {
        this.namespace.var(name, value);
      }
    }

    public fn(name: string, args: any, body: Function, inherit_scope: boolean = true) {
      const fn = new Func(name, args, body);
      fn.args_matcher = new Matcher(args);
      fn.parent_scope = this.scope;
      fn.inherit_scope = inherit_scope;
      if (name !== '') {
        this.namespace.var(name, fn);
      }

      return fn;
    }
  }

  export class Scope extends Base {
    constructor(parent: Scope, inherit_variables: boolean) {
      super(Scope);
      this.set('parent', parent);
      this.set('inherit_variables', inherit_variables);
      this.set('variables', {});
      this.set('ns_members', []);
    }

    get parent() {
      return this.get('parent');
    }

    get inherit_variables() {
      return this.get('inherit_variables');
    }

    get variables() {
      return this.get('variables');
    }

    get ns_members() {
      return this.get('ns_members');
    }

    public is_defined(name: string) {
      if (this.variables.hasOwnProperty(name)) {
        return true;
      } else if (this.parent) {
        if (this.inherit_variables) {
          return this.parent.is_defined(name);
        } else {
          // TODO: check in namespace
          return false;
        }
      }
    }

    public get_member(name: string) {
      if (this.variables.hasOwnProperty(name)) {
        return this.variables[name];
      } else if (this.parent) {
        if (this.inherit_variables) {
          return this.parent.get_member(name);
        } else {
          return this.parent.get_ns_member(name);
        }
      }
    }

    public set_member(name: string, value: any, options: any = {}) {
      this.variables[name] = value;

      if (options.namespace && this.ns_members.indexOf(name) < 0) {
        this.ns_members.push(name);
      }
    }

    public handle_arguments(matcher: Matcher, args: any) {
      for (const m of matcher.data_matchers) {
        this.set_member(m.name, args.get(m.index));
      }

      for (const m of matcher.prop_matchers) {
        this.set_member(m.name, args.get(m.name));
      }
    }
  }

  export class Func extends Base {
    constructor(name: string, args: [string], body: Function) {
      super(Func);
      this.set('name', name);
      this.set('args', args);
      this.set('body', body);
    }

    get name() {
      return this.get('name');
    }

    get args() {
      return this.get('args');
    }

    get body() {
      return this.get('body');
    }

    get parent_scope() {
      return this.get('parent_scope');
    }

    set parent_scope(scope: Scope) {
      this.set('parent_scope', scope);
    }

    get inherit_scope() {
      return this.get('inherit_scope');
    }

    set inherit_scope(value: boolean) {
      this.set('inherit_scope', value);
    }

    get args_matcher() {
      return this.get('args_matcher');
    }

    set args_matcher(value: Matcher) {
      this.set('args_matcher', value);
    }

    public invoke(context: Context, self: any, args: any) {
      const scope = new Scope(this.parent_scope, this.inherit_scope);

      scope.set_member('$function', this);
      scope.set_member('$caller_context', context);
      scope.handle_arguments(this.args_matcher, args);

      const new_context = context.extend({scope: scope, self: self});

      return this.body.call(undefined, new_context);
    }
  }

  export class Matcher extends Base {
    constructor(definition: any) {
      super(Matcher);
      this.set('data_matchers', []);
      this.set('prop_matchers', {});
      this.from_array(definition);
    }

    get data_matchers() {
      return this.get('data_matchers');
    }

    set data_matchers(value: any) {
      this.set('data_matchers', value);
    }

    get prop_matchers() {
      return this.get('prop_matchers');
    }

    set prop_matchers(value: any) {
      this.set('prop_matchers', value);
    }

    public get_matcher(name: string) {
      let matcher = this.prop_matchers[name];
      if (matcher) {
        return matcher;
      }

      for (matcher of this.data_matchers.length) {
        if (matcher.name === name) {
          return matcher;
        }
      }
    }

    private from_array(array: any) {
      if (!(array instanceof Array)) {
        array = [array];
      }

      let data_matcher: DataMatcher;
      let index = 0;
      let name;
      let expandable;
      let matched;

      while (index < array.length) {
        const item = array[index];
        index += 1;

        if (item === '=') {
          if (data_matcher) {
            data_matcher.default_value = array[index];
            index += 1;
            data_matcher = null;
          } else {
            throw new SyntaxError('Argument name is expected before `=`');
          }

        } else if (matched = item.match(/^\^\^(.*)$/)) {
          name = matched[0];
          if (this.get_matcher(name)) {
            throw new SyntaxError(`Name conflict: ${name}`);
          }
          this.prop_matchers[name] = new PropMatcher(name);
          data_matcher = null;

        } else if (matched = item.match(/^\^(.*)$/)) {
          name = matched[1];
          if (this.get_matcher(name)) {
            throw new SyntaxError(`Name conflict: ${name}`);
          }
          const prop_matcher = new PropMatcher(name);
          prop_matcher.default_value = array[index];
          index += 1;
          this.prop_matchers[name] = prop_matcher;
          data_matcher = null;

        } else {
          if (matched = item.match(/^(.*)(\.\.\.)$/)) {
            name = matched[1];
            expandable = true;
          } else {
            name = item;
            expandable = false;
          }

          if (this.get_matcher(name)) {
            throw new SyntaxError(`Name conflict: ${name}`);
          }
          data_matcher = new DataMatcher(name);
          data_matcher.expandable = expandable;
          this.data_matchers.push(data_matcher);
        }
      }

      this.calc_indexes();
    }

    private calc_indexes() {
      if (this.data_matchers.length <= 0) {
        return;
      }

      this.data_matchers.forEach((element: any, index: number) => {
        element.index = index;
      });

      const last = this.data_matchers[this.data_matchers.length - 1];
      if (last.expandable) {
        last.end_index = -1;
      }
    }
  }

  export class DataMatcher extends Base {
    constructor(name: string) {
      super(DataMatcher);
      this.set('name', name);
      this.set('default_value', undefined);
    }

    get name() {
      return this.get('name');
    }

    get index() {
      return this.get('index');
    }

    set index(value: number) {
      this.set('index', value);
    }

    get end_index() {
      return this.get('end_index');
    }

    set end_index(value: number) {
      this.set('end_index', value);
    }

    get expandable() {
      return this.get('expandable');
    }

    set expandable(value: boolean) {
      this.set('expandable', value);
    }

    get default_value() {
      return this.get('default_value');
    }

    set default_value(value: any) {
      this.set('default_value', value);
    }
  }

  export class PropMatcher extends Base {
    constructor(name: string) {
      super(PropMatcher);
      this.set('name', name);
      this.set('default_value', undefined);
    }

    get name() {
      return this.get('name');
    }

    get expandable() {
      return this.get('expandable');
    }

    set expandable(value: boolean) {
      this.set('expandable', value);
    }

    get default_value() {
      return this.get('default_value');
    }

    set default_value(value: any) {
      this.set('default_value', value);
    }
  }

  export class Variable extends Base {
    constructor(name: string) {
      super(Variable);
      this.set('name', name);
    }
    get name() {
      return this.get('name');
    }

    set name(value: string) {
      this.set('name', value);
    }

    get value() {
      return this.get('value');
    }

    set value(new_value: any) {
      this.set('value', new_value);
    }

    get default_value() {
      return this.get('default_value');
    }

    set default_value(value: any) {
      this.set('default_value', value);
    }
  }

  export class Argument extends Variable {
    constructor(name: string) {
      super(name);
      this.class = Argument;
    }

    get matcher() {
      return this.get('matcher');
    }

    set matcher(value: any) {
      this.matcher = value;
    }
  }

  export class Return extends Base {
    constructor(value: any) {
      super(Return);
      this.set('value', value);
    }

    get value() {
      return this.get('value');
    }
  }

  export class Throwable extends Base {
    constructor(reason: any) {
      super(Throwable);
      this.set('reason', reason);
    }

    get reason() {
      return this.get('reason');
    }
  }

  export class Exception extends Base {
    constructor(reason: any) {
      super(reason);
      this.class = Exception;
    }
  }

  export class Error extends Base {
    constructor(reason: any) {
      super(reason);
      this.class = Error;
    }
  }

  export class SyntaxError extends Error {
    constructor(reason: any) {
      super(reason);
      this.class = SyntaxError;
    }
  }

  export function assert(expr: any, message: string) {
    if (!expr) {
      throw message || 'AssertionError';
    }
  }
}

Gene['throw'] = function(error: any) {
  throw error;
};

Gene['return'] = function(value: any) {
  throw new Gene.Return(value);
};

let $application = new Gene.Application();
