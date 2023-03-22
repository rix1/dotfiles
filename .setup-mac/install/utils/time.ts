const format = new Intl.PluralRules("en-gb", { type: "ordinal" });

const ordinalMap = {
  zero: "s",
  one: "",
  two: "s",
  other: "s",
  few: "s",
  many: "s",
};

export function humanizeTime(num: number) {
  const inMinutes = num / 60;
  if (inMinutes < 1) {
    return `~${num} second${ordinalMap[format.select(num)]}`;
  }
  return `~${Math.floor(inMinutes)} minute${
    ordinalMap[format.select(inMinutes)]
  }`;
}

export function sumTime(timeArr: number[]) {
  return humanizeTime(timeArr.reduce((prev, next) => prev + next, 0));
}
