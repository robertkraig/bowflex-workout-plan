export type PageConfig = {
  pageIndex?: number;
  page?: number;
};

export type Config = {
  file?: string;
  output?: string;
  pages?: PageConfig[];
  appendFirstPage?: string;
};

export type CommandOptions = {
  input?: string;
  output?: string;
  yaml?: string;
  markdown?: string;
};
