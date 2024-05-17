import { connect } from '@permaweb/aoconnect';
import { JWKInterface } from 'arbundles';
import 'arconnect'

export interface AoClient {
  processId: string;
  scheduler?: string; // arweave txid of schedular location
  ao: {
    message: any;
    result: any;
    results: any;
    dryrun: any;
    spawn: any;
    monitor: any;
    unmonitor: any;
  };
}

export type AoProviderParams = {
  processId: string;
  signer: JWKInterface | Window['arweaveWallet'];
  scheduler?: string;
  connectConfig?: any;
};

export class AoProvider implements AoClient {
  processId: string;
  signer: JWKInterface | Window['arweaveWallet'];
  scheduler?: string;
  ao: {
    message: any;
    result: any;
    results: any;
    dryrun: any;
    spawn: any;
    monitor: any;
    unmonitor: any;
  };

  constructor({
    processId,
    signer,
    scheduler,
    connectConfig,
  }: AoProviderParams) {
    this.signer = signer;
    this.processId = processId;
    this.scheduler = scheduler;
    this.ao = connect(connectConfig);
  }
}
