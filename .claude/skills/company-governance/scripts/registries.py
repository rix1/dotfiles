#!/usr/bin/env python3
"""Look up a company in public business registries. Stdlib only.

  registries.py edgar "Company name" [--ua "Your Name you@example.com"]
      SEC EDGAR: every Form D on file, with offering size, investor count
      and the related persons (officers and directors) named on each.
      The SEC requires a User-Agent with contact info: pass --ua or set EDGAR_UA.

  registries.py brreg "Company name" [--orgnr 123456789]
      Norway (Brønnøysundregistrene): matching entities, then the roles
      (CEO, board, auditor) for the best match or the given org number.

  registries.py cvr "Company name or CVR number"
      Denmark (via cvrapi.dk): best match, owners, credit/bankruptcy flags.
      Name search is fuzzy; prefer the CVR number when you have it.
"""
import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request


def get(url, ua="registries.py (github.com/rix1/dotfiles)"):
    req = urllib.request.Request(url, headers={"User-Agent": ua, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def get_json(url, ua=None):
    return json.loads(get(url, ua) if ua else get(url))


# --- SEC EDGAR -------------------------------------------------------------

def tag(xml, name):
    return [t.strip() for t in re.findall(r"<%s>(.*?)</%s>" % (name, name), xml, re.S)]


def edgar(name, ua):
    if not ua:
        sys.exit("EDGAR needs a User-Agent with contact info: --ua 'Name email' or EDGAR_UA=...")
    q = urllib.parse.quote('"%s"' % name)
    fts = get_json("https://efts.sec.gov/LATEST/search-index?q=%s&forms=D" % q, ua)
    hits = fts.get("hits", {}).get("hits", [])
    print("Form D hits for %r: %d" % (name, len(hits)))
    ciks = []
    for h in hits:
        src = h["_source"]
        acc, _, fname = h["_id"].partition(":")
        cik = src["ciks"][0]
        if cik not in ciks:
            ciks.append(cik)
        url = "https://www.sec.gov/Archives/edgar/data/%s/%s/%s" % (int(cik), acc.replace("-", ""), fname)
        print("\n== %s %s  %s\n   %s" % (src.get("file_date"), src.get("form"), src.get("display_names"), url))
        try:
            x = get(url, ua)
        except Exception as e:  # noqa: BLE001
            print("   (could not fetch: %s)" % e)
            continue
        year = tag(" ".join(tag(x, "yearOfInc")), "value")
        first_sale = tag(" ".join(tag(x, "dateOfFirstSale")), "value")
        print("   entity: %s | jurisdiction: %s | type: %s | inc. year: %s" % (
            ", ".join(tag(x, "entityName")), ", ".join(tag(x, "jurisdictionOfInc")),
            ", ".join(tag(x, "entityType")), ", ".join(year) or "?"))
        print("   offering: total %s | sold %s | remaining %s | investors so far %s | first sale %s" % (
            " ".join(tag(x, "totalOfferingAmount")), " ".join(tag(x, "totalAmountSold")),
            " ".join(tag(x, "totalRemaining")), " ".join(tag(x, "totalNumberAlreadyInvested")),
            " ".join(first_sale) or "?"))
        eq = "equity" if tag(x, "isEquityType") == ["true"] else "non-equity"
        print("   securities: %s" % eq)
        print("   related persons (officers, directors, promoters):")
        for blk in re.findall(r"<relatedPersonInfo>(.*?)</relatedPersonInfo>", x, re.S):
            print("     - %s %s: %s" % (" ".join(tag(blk, "firstName")), " ".join(tag(blk, "lastName")),
                                        ", ".join(tag(blk, "relationship"))))
        for c in tag(x, "clarificationOfResponse"):
            if c:
                print("   note: %s" % c)
    for cik in ciks:
        sub = get_json("https://data.sec.gov/submissions/CIK%010d.json" % int(cik), ua)
        f = sub["filings"]["recent"]
        print("\nAll EDGAR filings for %s (CIK %s, inc. %s):" % (sub.get("name"), cik, sub.get("stateOfIncorporation")))
        for i in range(len(f["form"])):
            print("   %s  %s  %s" % (f["filingDate"][i], f["form"][i], f["accessionNumber"][i]))
    if not hits:
        print("No Form D on file. Not unusual for a private company, but it means no public record of the board.")


# --- Norway ----------------------------------------------------------------

def brreg(name, orgnr=None):
    base = "https://data.brreg.no/enhetsregisteret/api/enheter"
    if not orgnr:
        d = get_json("%s?navn=%s&size=10" % (base, urllib.parse.quote(name)))
        ents = d.get("_embedded", {}).get("enheter", [])
        print("Matches for %r: %d" % (name, len(ents)))
        for e in ents:
            print("   %s  %-40s %-4s founded %s  employees %s%s%s" % (
                e.get("organisasjonsnummer"), e.get("navn"), e.get("organisasjonsform", {}).get("kode"),
                e.get("stiftelsesdato"), e.get("antallAnsatte"),
                "  BANKRUPT" if e.get("konkurs") else "",
                "  UNDER FORCED LIQUIDATION" if e.get("underTvangsavviklingEllerTvangsopplosning") else ""))
        if not ents:
            return
        orgnr = ents[0]["organisasjonsnummer"]
    r = get_json("%s/%s/roller" % (base, orgnr))
    print("\nRoles for %s:" % orgnr)
    for g in r.get("rollegrupper", []):
        print("   %s (%s)" % (g["type"].get("beskrivelse"), g["type"]["kode"]))
        for role in g.get("roller", []):
            p = role.get("person") or role.get("enhet") or {}
            n = p.get("navn")
            if isinstance(n, dict):
                n = " ".join(filter(None, [n.get("fornavn"), n.get("mellomnavn"), n.get("etternavn")]))
            extra = " (resigned)" if role.get("fratraadt") else ""
            print("      %-5s %s%s" % (role["type"]["kode"], n, extra))


# --- Denmark ---------------------------------------------------------------

def cvr(query):
    d = get_json("https://cvrapi.dk/api?search=%s&country=dk" % urllib.parse.quote(query))
    if "error" in d:
        print("cvrapi.dk: %s" % d["error"])
        return
    print("Best match for %r (name search is fuzzy; check the name!):" % query)
    for k in ("vat", "name", "companydesc", "startdate", "enddate", "employees", "address", "zipcode", "city",
              "addressco", "industrydesc", "creditbankrupt", "creditstartdate", "creditstatus"):
        print("   %-16s %s" % (k, d.get(k)))
    print("   owners           %s" % ", ".join(o.get("name", "?") for o in d.get("owners", [])))
    if d.get("creditbankrupt"):
        print("   ! creditbankrupt=true usually means bankruptcy or forced dissolution proceedings. "
              "Confirm on datacvr.virk.dk or proff.dk before repeating it.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("edgar"); e.add_argument("name"); e.add_argument("--ua", default=os.environ.get("EDGAR_UA"))
    b = sub.add_parser("brreg"); b.add_argument("name"); b.add_argument("--orgnr")
    c = sub.add_parser("cvr"); c.add_argument("query")
    a = ap.parse_args()
    if a.cmd == "edgar":
        edgar(a.name, a.ua)
    elif a.cmd == "brreg":
        brreg(a.name, a.orgnr)
    else:
        cvr(a.query)


if __name__ == "__main__":
    main()
