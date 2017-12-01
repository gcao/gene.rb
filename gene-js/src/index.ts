namespace Gene {
  export class Object {
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
      const obj = new Object(klass);
      obj.properties = this.properties;

      return obj;
    }
  }

  export class Module extends Object {
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

  export class Context extends Object {
  }

  export function var_(name: string, value: any) {
    return (context: Gene.Context) => {
      context.set(name, value(context));
    };
  }
}
