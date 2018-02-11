namespace Gene {
  export class Base {
    public class: any;
    public properties: object;

    constructor(_class: any) {
      this.properties = {};
      this.class = _class;
    }

    public get(name: string) {
      return this.properties[name];
    }

    public set(name: string, value: any) {
      this.properties[name] = value;
    }

    get data() {
      return this.get('#data');
    }
    set data(data: [any]) {
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
      return this.methods[name]
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
      return this.members.include(name);
    }

    public get_member(name: string) {
      return this.members[name];
    }

    public set_member(name: string, value: any) {
      this.members[name] = value;
    }

    public ["var"](name: string, value: any) {
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
      context.self = context.namespace = new Namespace('root', this.global_namespace);

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
        this.namespace = options.namespace;
      }
      if (options.scope) {
        this.scope = options.scope;
      }
      if (options.self) {
        this.self = options.self;
      }

      return new_context;
    }

    public ['var'](name: string, value: any) {
      this.namespace.var(name, value);
    }

    public get_member(name: string) {
      return this.namespace.get_member(name);
    }

    public set_member(name: string, value: any) {
      this.namespace.set_member(name, value);
    }
  }

  export class Scope extends Base {
    constructor(parent: Scope, inherit_variables: boolean) {
      super(Scope);
      this.set('parent', parent);
      this.set('inherit_variables', inherit_variables);
      this.set('variables', {});
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

    public is_defined(name: string): boolean {
      return this.variables.hasOwnProperty(name);
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

    public invoke(options: {context: Context}) {
      const { context } = options;

      return this.body.call(context);
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
