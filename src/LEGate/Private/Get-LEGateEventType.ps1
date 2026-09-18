function Get-LEGateEventType {
    <# .SYNOPSIS
    Returns EventType values from the reviewed v8-preview snapshot, without a runtime spec dependency.
    #>
    [CmdletBinding()]
    param()
    return @(
        'launcherOffline', 'connectionInitializationTimeout', 'loginFailure', 'sessionFailure',
        'applicationFailure', 'launcherCapacityExceeded', 'accountCapacityExceeded', 'applicationThresholdExceeded',
        'emailFailure', 'sessionDiscoveryError', 'scriptEvent', 'latencyThresholdExceeded', 'loginTimeThresholdExceeded',
        'latencyMeasurementFailed', 'loginTimeMeasurementFailed', 'emailRequest', 'accountDisabled',
        'sessionRequestEndedBeforeEngineBecameOnline', 'licenseSessionLimit', 'testRunStarted', 'testRunCancelled',
        'testRunFailed', 'testRunFinished', 'appExecutionAbandoned', 'enginePaused', 'engineResumed',
        'remoteSessionDisconnected', 'scriptScreenshot', 'screenshotFailure', 'dataRetentionStarted',
        'dataRetentionFinished', 'dataRetentionFailed', 'databaseFailure', 'euxInitializationFailure',
        'euxExecutionFailure', 'engineLogs', 'launcherLogs', 'customUserSessionEvent'
    )
}
