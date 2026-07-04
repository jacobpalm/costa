unit UITIMER;

interface

uses
	Costalib;

type
	PTimer = ^TTimer;
	TTimer = object(TUIObject)
		public
			constructor  Init(Parent: PContainer);
			procedure    CheckEvent; virtual;
			procedure    Draw; virtual;

			procedure    Start;
			procedure    Stop;
			function     IsRunning: boolean;

			procedure    SetInterval(Seconds: Real);
			function     GetInterval: Real;
		private
			Interval,
			LastTick:    real;
			Running:     boolean;
	end;

implementation

constructor TTimer.Init(Parent: PContainer);
const
	DefaultW = 92;
	DefaultH = 22;
begin
	TUIObject.Init;
	Interval := 0;
	LastTick := 0;
	Running := False;
	SetParent(Parent);
end;

procedure TTimer.CheckEvent;
begin
	{Don't check for events if timer is disabled or not running}
	if not (SEnabled in State) or not Running then
		exit;

	{Check if interval time has passed since last tick}
	if Timer > LastTick + Interval then
	begin
		{Update last tick time}
		LastTick := Timer;

		{Trigger OnClick event, if assigned}
		Self.Click;
	end;
end;

procedure TTimer.Draw;
begin
	{Dummy procedure - Timer has no visual representation. Only used to override
	 TUIObject.Draw which triggers an OnDraw event}
	if SDirty in State then
		Exclude(State, SDirty);
end;

procedure TTimer.Start;
begin
	{Can't run a timer with no interval, would trigger constantly}
	if Interval = 0 then
		exit;

	{Start the timer and set its last tick to the current time, so that when interval passes
	 from now the timer can trigger its OnTick event}
	Running := True;
	LastTick := Timer;
end;

procedure TTimer.Stop;
begin
	Running := False;
end;

function TTimer.IsRunning: boolean;
begin
	IsRunning := Running;
end;

procedure TTimer.SetInterval(Seconds: Real);
begin
	Interval := Seconds;

	{If timer is running, reset last tick to current time}
	if Running then
		LastTick := Timer;
end;

function TTimer.GetInterval: Real;
begin
	GetInterval := Interval;
end;

end.