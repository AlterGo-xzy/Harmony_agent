import { AGENT_CONTRACT_SCHEMA_VERSION, CONTRACT_TYPE_ARTIFACT_MANIFEST } from './Constants';
import { ContractId, Digest, IsoTimestamp, JsonText } from './Common';
import { ArtifactLifecycleStatus } from './Enums';

export class ArtifactManifest {
  schemaVersion: string = AGENT_CONTRACT_SCHEMA_VERSION;
  contractType: string = CONTRACT_TYPE_ARTIFACT_MANIFEST;
  artifactId: ContractId = '';
  algorithm: string = '';
  artifactVersion: string = '';
  sourceCommit: string = '';
  sourceLicense: string = '';
  trainingDataLineage: string[] = [];
  modelAndProviderSnapshotJson: JsonText = '{}';
  featureSchemaVersion: string = '';
  runtimeCompatibility: string[] = [];
  checkpointDigest: Digest = '';
  paperReproductionResultsJson: JsonText = '{}';
  portParityResultsJson: JsonText = '{}';
  harmonyAgentBenchResultsJson: JsonText = '{}';
  lifecycleStatus: ArtifactLifecycleStatus = ArtifactLifecycleStatus.DISABLED;
  approvalStatus: string = '';
  signedAt?: IsoTimestamp;
}
