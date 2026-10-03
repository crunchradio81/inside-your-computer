package com.retrothemes.insideyourcomputer

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.AttributeSet
import android.view.View
import kotlin.math.max
import kotlin.random.Random

class InsideComputerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    private data class Actor(
        val resourceId: Int,
        val frames: List<Bitmap>,
        val delayTicks: Int,
        val dx: Float,
        val dy: Float,
        val soundNumber: Int,
        var x: Float,
        var y: Float,
        var tick: Int = 0,
        var frameIndex: Int = 0
    )

    companion object {
        private const val LOGICAL_HEIGHT = 480f
        private const val SIMULATION_INTERVAL_MS = 125L
        private const val MOVEMENT_ADVANCE_DIVISOR = 2
        private const val FIRST_AMBIENT_SOUND_TICK = 48
        private const val MIN_SOUND_GAP_MS = 4_000L
        private const val SAME_SOUND_GAP_MS = 6_000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        isFilterBitmap = false
        isDither = false
    }

    private val board: Bitmap =
        BitmapFactory.decodeResource(resources, R.drawable.board)

    private val actors: MutableList<Actor> = makeActors().toMutableList()

    private var visibleLogicalWidth = 640f
    private var running = false
    private var globalTick = 0
    private var pacingTick = 0
    private var nextAmbientSoundTick = FIRST_AMBIENT_SOUND_TICK
    private var nextAmbientSoundNumber = 1
    private var lastAnySoundAt = 0L
    private val lastSoundByNumber = mutableMapOf<Int, Long>()

    private val soundPool: SoundPool
    private val sounds = mutableMapOf<Int, Int>()
    private var currentlyPlayingStream = 0

    private val simulationRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            advanceSimulation()
            invalidate()
            handler.postDelayed(this, SIMULATION_INTERVAL_MS)
        }
    }

    init {
        setBackgroundColor(Color.BLACK)
        keepScreenOn = true

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(1)
            .setAudioAttributes(audioAttributes)
            .build()

        sounds[1] = soundPool.load(context, R.raw.sound1, 1)
        sounds[2] = soundPool.load(context, R.raw.sound2, 1)
        sounds[3] = soundPool.load(context, R.raw.sound3, 1)
        sounds[4] = soundPool.load(context, R.raw.sound4, 1)
        sounds[5] = soundPool.load(context, R.raw.sound5, 1)
        sounds[6] = soundPool.load(context, R.raw.sound6, 1)
        sounds[7] = soundPool.load(context, R.raw.sound7, 1)
        sounds[8] = soundPool.load(context, R.raw.sound8, 1)
    }

    fun start() {
        if (running) return
        running = true
        handler.removeCallbacks(simulationRunnable)
        handler.post(simulationRunnable)
    }

    fun stop() {
        running = false
        handler.removeCallbacks(simulationRunnable)
        stopCurrentSound()
    }

    fun release() {
        stop()
        soundPool.release()
    }

    override fun onDetachedFromWindow() {
        stop()
        super.onDetachedFromWindow()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawColor(Color.BLACK)

        if (height <= 0) return

        val scale = height.toFloat() / LOGICAL_HEIGHT
        if (scale <= 0f) return

        visibleLogicalWidth = width.toFloat() / scale

        canvas.save()
        canvas.scale(scale, scale)
        drawBoard(canvas)
        drawActors(canvas)
        canvas.restore()
    }

    private fun drawBoard(canvas: Canvas) {
        val tileW = board.width.toFloat()
        val tileH = board.height.toFloat()

        var y = 0f
        while (y < LOGICAL_HEIGHT) {
            var x = 0f
            while (x < visibleLogicalWidth) {
                canvas.drawBitmap(board, x, y, paint)
                x += tileW
            }
            y += tileH
        }
    }

    private fun drawActors(canvas: Canvas) {
        for (actor in actors) {
            val image = actor.frames[actor.frameIndex]
            val androidY = LOGICAL_HEIGHT - actor.y - image.height
            canvas.drawBitmap(image, actor.x, androidY, paint)
        }
    }

    private fun advanceSimulation() {
        globalTick += 1
        pacingTick += 1

        val advanceMotion =
            pacingTick % MOVEMENT_ADVANCE_DIVISOR == 0

        if (advanceMotion) {
            actors.forEach { actor ->
                actor.tick += 1
                if (actor.tick < actor.delayTicks) {
                    return@forEach
                }
                actor.tick = 0

                actor.x += actor.dx
                actor.y += actor.dy
                actor.frameIndex =
                    (actor.frameIndex + 1) % actor.frames.size

                val image = actor.frames[actor.frameIndex]
                val margin =
                    max(image.width, image.height).toFloat() + 30f

                var wrapped = false

                if (actor.x > visibleLogicalWidth + margin) {
                    actor.x = -image.width.toFloat()
                    wrapped = true
                } else if (actor.x < -image.width - margin) {
                    actor.x = visibleLogicalWidth + 10f
                    wrapped = true
                }

                if (actor.y > LOGICAL_HEIGHT + margin) {
                    actor.y = -image.height.toFloat()
                    wrapped = true
                } else if (actor.y < -image.height - margin) {
                    actor.y = LOGICAL_HEIGHT + 10f
                    wrapped = true
                }

                if (wrapped) {
                    playSound(actor.soundNumber)
                }
            }
        }

        if (globalTick >= nextAmbientSoundTick) {
            playSound(nextAmbientSoundNumber)

            nextAmbientSoundNumber += 1
            if (nextAmbientSoundNumber > 8) {
                nextAmbientSoundNumber = 1
            }

            nextAmbientSoundTick =
                globalTick + Random.nextInt(96, 145)
        }
    }

    private fun playSound(number: Int) {
        val now = SystemClock.elapsedRealtime()

        if (currentlyPlayingStream != 0) return

        if (lastAnySoundAt != 0L &&
            now - lastAnySoundAt < MIN_SOUND_GAP_MS
        ) {
            return
        }

        val sameLast = lastSoundByNumber[number]
        if (sameLast != null &&
            now - sameLast < SAME_SOUND_GAP_MS
        ) {
            return
        }

        val soundId = sounds[number] ?: return

        currentlyPlayingStream = soundPool.play(
            soundId,
            0.85f,
            0.85f,
            1,
            0,
            1.0f
        )

        if (currentlyPlayingStream != 0) {
            lastAnySoundAt = now
            lastSoundByNumber[number] = now

            handler.postDelayed({
                currentlyPlayingStream = 0
            }, 2500L)
        }
    }

    private fun stopCurrentSound() {
        if (currentlyPlayingStream != 0) {
            soundPool.stop(currentlyPlayingStream)
            currentlyPlayingStream = 0
        }
    }

    private fun makeActors(): List<Actor> {
        return listOf(
            actor(8802, 2,  1f,  1f, 1, -120f,  45f),
            actor(8803, 1,  1f, -1f, 2,  120f, 460f),
            actor(8804, 1, -2f,  0f, 3,  700f, 300f),
            actor(8805, 1, -1f, -2f, 4,  580f, 520f),
            actor(8806, 1,  0f,  2f, 5,  310f,-100f),
            actor(8807, 1,  0f, -3f, 6,  475f, 560f),
            actor(8808, 1,  2f, -2f, 7, -120f, 430f)
        )
    }

    private fun actor(
        resourceId: Int,
        delayTicks: Int,
        dx: Float,
        dy: Float,
        soundNumber: Int,
        x: Float,
        y: Float
    ): Actor {
        val frames = (0 until 12).map { index ->
            val name =
                "sprite_${resourceId}_${index.toString().padStart(2, '0')}"
            val drawableId =
                resources.getIdentifier(name, "drawable", context.packageName)

            check(drawableId != 0) {
                "Missing renderer frame: $name"
            }

            BitmapFactory.decodeResource(resources, drawableId)
        }

        return Actor(
            resourceId = resourceId,
            frames = frames,
            delayTicks = delayTicks,
            dx = dx,
            dy = dy,
            soundNumber = soundNumber,
            x = x,
            y = y
        )
    }
}
