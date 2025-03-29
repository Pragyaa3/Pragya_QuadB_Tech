#![allow(clippy::result_large_err)]

use anchor_lang::prelude::*;

declare_id!("coUnmi3oBUtwtd9fjeAvSsJssXh5A5xyPbhpewyzRVF");

#[program]
pub mod trackr {
    use super::*;

  pub fn close(_ctx: Context<CloseTrackr>) -> Result<()> {
    Ok(())
  }

  pub fn decrement(ctx: Context<Update>) -> Result<()> {
    ctx.accounts.trackr.count = ctx.accounts.trackr.count.checked_sub(1).unwrap();
    Ok(())
  }

  pub fn increment(ctx: Context<Update>) -> Result<()> {
    ctx.accounts.trackr.count = ctx.accounts.trackr.count.checked_add(1).unwrap();
    Ok(())
  }

  pub fn initialize(_ctx: Context<InitializeTrackr>) -> Result<()> {
    Ok(())
  }

  pub fn set(ctx: Context<Update>, value: u8) -> Result<()> {
    ctx.accounts.trackr.count = value.clone();
    Ok(())
  }
}

#[derive(Accounts)]
pub struct InitializeTrackr<'info> {
  #[account(mut)]
  pub payer: Signer<'info>,

  #[account(
  init,
  space = 8 + Trackr::INIT_SPACE,
  payer = payer
  )]
  pub trackr: Account<'info, Trackr>,
  pub system_program: Program<'info, System>,
}
#[derive(Accounts)]
pub struct CloseTrackr<'info> {
  #[account(mut)]
  pub payer: Signer<'info>,

  #[account(
  mut,
  close = payer, // close account and return lamports to payer
  )]
  pub trackr: Account<'info, Trackr>,
}

#[derive(Accounts)]
pub struct Update<'info> {
  #[account(mut)]
  pub trackr: Account<'info, Trackr>,
}

#[account]
#[derive(InitSpace)]
pub struct Trackr {
  count: u8,
}
