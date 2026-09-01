use std::collections::HashSet;
use std::ffi::{c_char, c_int, c_void, CStr, CString};
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

type Sqlite3 = c_void;
type Sqlite3Stmt = c_void;

const SQLITE_OK: c_int = 0;
const SQLITE_ROW: c_int = 100;

#[link(name = "sqlite3")]
unsafe extern "C" {
    fn sqlite3_open_v2(
        filename: *const c_char,
        pp_db: *mut *mut Sqlite3,
        flags: c_int,
        z_vfs: *const c_char,
    ) -> c_int;
    fn sqlite3_close(db: *mut Sqlite3) -> c_int;
    fn sqlite3_prepare_v2(
        db: *mut Sqlite3,
        z_sql: *const c_char,
        n_byte: c_int,
        pp_stmt: *mut *mut Sqlite3Stmt,
        pz_tail: *mut *const c_char,
    ) -> c_int;
    fn sqlite3_step(stmt: *mut Sqlite3Stmt) -> c_int;
    fn sqlite3_finalize(stmt: *mut Sqlite3Stmt) -> c_int;
    fn sqlite3_column_int(stmt: *mut Sqlite3Stmt, i_col: c_int) -> c_int;
    fn sqlite3_errmsg(db: *mut Sqlite3) -> *const c_char;
}

const SQLITE_OPEN_READONLY: c_int = 0x00000001;

fn git_root(cwd: &Path) -> Option<PathBuf> {
    for candidate in cwd.ancestors() {
        if candidate.join(".git").exists() {
            return Some(candidate.to_path_buf());
        }
    }
    None
}

fn claude_project_name(path: &Path) -> String {
    path.to_string_lossy().replace('/', "-").replace('.', "-")
}

fn count_claude(home: &Path, paths: &HashSet<PathBuf>) -> usize {
    let projects_dir = home.join(".claude/projects");
    let mut count = 0;

    for path in paths {
        let project_dir = projects_dir.join(claude_project_name(path));
        let Ok(entries) = fs::read_dir(project_dir) else {
            continue;
        };

        for entry in entries.flatten() {
            if entry.path().extension().is_some_and(|extension| extension == "jsonl") {
                count += 1;
            }
        }
    }

    count
}

fn sql_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "''"))
}

fn count_codex(home: &Path, paths: &HashSet<PathBuf>) -> usize {
    let db = home.join(".codex/state_5.sqlite");
    if !db.is_file() || paths.is_empty() {
        return 0;
    }

    let cwd_list = paths
        .iter()
        .map(|path| sql_quote(&path.to_string_lossy()))
        .collect::<Vec<_>>()
        .join(",");
    let query = format!(
        "select count(distinct id) from threads where cwd in ({});",
        cwd_list
    );

    run_sql_count(&db, &query).unwrap_or(0)
}

fn run_sql_count(db_path: &Path, query: &str) -> Option<usize> {
    let db_path = CString::new(db_path.to_string_lossy().as_bytes()).ok()?;
    let query = CString::new(query).ok()?;
    let mut db: *mut Sqlite3 = std::ptr::null_mut();

    unsafe {
        if sqlite3_open_v2(
            db_path.as_ptr(),
            &mut db,
            SQLITE_OPEN_READONLY,
            std::ptr::null(),
        ) != SQLITE_OK
        {
            return None;
        }

        let mut stmt: *mut Sqlite3Stmt = std::ptr::null_mut();
        if sqlite3_prepare_v2(db, query.as_ptr(), -1, &mut stmt, std::ptr::null_mut()) != SQLITE_OK
        {
            let _ = CStr::from_ptr(sqlite3_errmsg(db));
            sqlite3_close(db);
            return None;
        }

        let result = if sqlite3_step(stmt) == SQLITE_ROW {
            let count = sqlite3_column_int(stmt, 0);
            if count >= 0 {
                Some(count as usize)
            } else {
                None
            }
        } else {
            None
        };

        sqlite3_finalize(stmt);
        sqlite3_close(db);
        result
    }
}

fn main() {
    let home = env::var_os("HOME").map(PathBuf::from).unwrap_or_else(|| PathBuf::from("/"));
    let claude_icon = env::var("LLM_COUNT_CLAUDE_ICON").unwrap_or_else(|_| "✻".to_string());
    let codex_icon = env::var("LLM_COUNT_CODEX_ICON").unwrap_or_else(|_| "󰚩".to_string());

    let Ok(cwd) = env::current_dir() else {
        std::process::exit(1);
    };
    let mut paths = HashSet::from([cwd.clone()]);
    if let Some(root) = git_root(&cwd) {
        paths.insert(root);
    }

    let claude_count = count_claude(&home, &paths);
    let codex_count = count_codex(&home, &paths);
    let mut parts = Vec::new();

    if claude_count > 0 {
        parts.push(format!("{} {}", claude_icon, claude_count));
    }
    if codex_count > 0 {
        parts.push(format!("{} {}", codex_icon, codex_count));
    }

    if parts.is_empty() {
        std::process::exit(1);
    }

    println!("{}", parts.join(" "));
}
