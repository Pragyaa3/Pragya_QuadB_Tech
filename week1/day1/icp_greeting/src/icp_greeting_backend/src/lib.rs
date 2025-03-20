use ic_cdk::export_candid;

#[ic_cdk::query]
fn greet(name: String) -> String {
    format!("Hello, {}! Welcome to ICP!", name)
}

export_candid!();
